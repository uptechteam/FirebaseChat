//
//  MessagesProvider.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import Foundation
import FirebaseDatabase
import ObjectMapper
import ReactiveSwift
import Result

private let DefaultMessagesBatchCount = 5

enum MessagesProviderError: Swift.Error {
    case wrapped(Swift.Error)
}

final class MessagesProvider {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    func fetchMessageEntities(
        chatEntity: FirebaseEntity<Chat>,
        loadMoreMessages: Signal<Void, NoError>
        ) -> Property<[FirebaseEntity<Message>]> {

        let reference = database.reference(withPath: "messages/\(chatEntity.identifier)")

        func loadMessageEntitiesOnce(limit: Int, cursor: FirebaseEntity<Message>) -> SignalProducer<[FirebaseEntity<Message>], MessagesProviderError> {
            let query = reference
                .queryOrdered(byChild: "date")
                .queryEnding(atValue: cursor.model.date.timeIntervalSince1970, childKey: "date")
                .queryLimited(toLast: UInt(limit))

            return SignalProducer { (observer: Signal<[FirebaseEntity<Message>], MessagesProviderError>.Observer, _: Lifetime) in
                query.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                    guard let json = snapshot.value as? [String: Any] else {
                        observer.send(value: [])
                        observer.sendCompleted()
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

                        observer.send(value: entities)
                        observer.sendCompleted()
                    } catch {
                        observer.send(error: .wrapped(error))
                    }
                }, withCancel: { (error) in
                    observer.send(error: .wrapped(error))
                })
            }
        }

        let newMessages = Signal<FirebaseEntity<Message>, MessagesProviderError> { (observer, lifetime) in
            let query = reference
                .queryOrdered(byChild: "date")
                .queryLimited(toLast: UInt(DefaultMessagesBatchCount))

            let handle = query.observe(.childAdded) { (snapshot) in
                guard let rawMessage = snapshot.value as? [String: Any] else {
                    return
                }

                do {
                    let model: Message = try Mapper<Message>().map(JSON: rawMessage)
                    observer.send(value: FirebaseEntity(identifier: snapshot.key, model: model))
                } catch {
                    observer.send(error: .wrapped(error))
                }
            }

            lifetime.observeEnded {
                reference.removeObserver(withHandle: handle)
            }
        }

        let messages = newMessages
            .scan([FirebaseEntity<Message>]()) { (accum, messageEntity) in
                return (accum + [messageEntity]).sorted(by: { $0.model.date < $1.model.date })
            }
            .flatMapError { _ in SignalProducer<[FirebaseEntity<Message>], NoError>.empty }

        let messagesProperty = Property(initial: [], then: messages)

        return messagesProperty
    }

    func post(message: Message, to chatEntity: FirebaseEntity<Chat>) -> SignalProducer<Void, MessagesProviderError> {
        let reference = self.database.reference(withPath: "messages/\(chatEntity.identifier)")
        return SignalProducer { observer, lifetime in
            let mapper = Mapper<Message>()
            let json = mapper.toJSON(message)
            reference.childByAutoId().setValue(json) { (error, reference) in
                if let error = error {
                    observer.send(error: .wrapped(error))
                } else {
                    observer.send(value: ())
                    observer.sendCompleted()
                }
            }
        }
    }
}
