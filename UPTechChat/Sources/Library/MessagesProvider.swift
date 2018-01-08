//
//  MessagesProvider.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import Foundation
import FirebaseDatabase
import RxSwift
import ObjectMapper

private let DefaultMessagesBatchCount = 5

struct MessagesResult {
    let entities: Observable<[FirebaseEntity<Message>]>
}

final class MessagesProvider {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    func fetchMessageEntities(
        chatEntity: FirebaseEntity<Chat>,
        reloadMessages: Observable<Void>,
        loadMoreMessages: Observable<Void>
        ) -> Observable<[FirebaseEntity<Message>]> {

        let reference = database.reference(withPath: "messages/\(chatEntity.identifier)")

        func loadMessageEntitiesOnce(limit: Int) -> Observable<[FirebaseEntity<Message>]> {
            let query = reference.queryOrdered(byChild: "date").queryLimited(toLast: UInt(limit))
            return Observable.create { observer in
                query.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                    guard let json = snapshot.value as? [String: Any] else {
                        observer.onNext([])
                        return
                    }

                    do {
                        let mapper = Mapper<Message>()
                        let entities = try json
                            .map { (key, value) -> FirebaseEntity<Message> in
                                let model = try mapper.map(JSONObject: value)
                                return FirebaseEntity(identifier: key, model: model)
                            }
                            .sorted(by: { $0.model.date < $1.model.date })

                        observer.onNext(entities)
                    } catch {
                        observer.onError(error)
                    }
                }, withCancel: { (error) in
                    observer.onError(error)
                })

                return Disposables.create()
            }
        }

        let newMessages = Observable<FirebaseEntity<Message>>.create { observer in
            let handle = reference.observe(DataEventType.childAdded) { (snapshot) in
                guard let rawMessage = snapshot.value as? [String: Any] else {
                    return
                }

                do {
                    let model: Message = try Mapper<Message>().map(JSON: rawMessage)
                    observer.onNext(FirebaseEntity(identifier: snapshot.key, model: model))
                } catch {
                    observer.onError(error)
                }
            }

            return Disposables.create {
                reference.removeObserver(withHandle: handle)
            }
        }

        let staticMessages = reloadMessages
            .flatMapLatest { () -> Observable<[FirebaseEntity<Message>]> in
                let initialMessages = loadMessageEntitiesOnce(limit: DefaultMessagesBatchCount)

                initialMessages
                    

                return loadMoreMessages
                    .startWith(())
                    .scan(0, accumulator: { (accum: Int, _: Void) -> Int in
                        return accum + DefaultMessagesBatchCount
                    })
                    .flatMapLatest(loadMessageEntitiesOnce)
            }

        return .never()
    }

    func post(message: Message, to chatEntity: FirebaseEntity<Chat>) -> Observable<Void> {
        let reference = database.reference(withPath: "messages/\(chatEntity.identifier)")
        return Observable.create { observer in
            let mapper = Mapper<Message>()
            let json = mapper.toJSON(message)
            reference.childByAutoId().setValue(json, withCompletionBlock: { (error, _) in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            })

            return Disposables.create()
        }
    }
}
