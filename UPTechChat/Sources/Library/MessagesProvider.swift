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

private let DefaultMessagesBatchCount = 50

enum MessagesProviderError: Swift.Error {
    case wrapped(Swift.Error)
}

struct MessagesResult {
    let messages: Property<[FirebaseEntity<Message>]>
    let isLoadingMore: Property<Bool>
    let errors: Signal<MessagesProviderError, NoError>
}

final class MessagesProvider {
    private let database: Database
    private let scheduler: QueueScheduler

    init(database: Database, scheduler: QueueScheduler = .messages) {
        self.database = database
        self.scheduler = scheduler
    }

    func fetchMessageEntities(
        chatEntity: FirebaseEntity<Chat>,
        loadMoreMessages: Signal<Void, NoError>
        ) -> MessagesResult {

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
                .start(on: self.scheduler)
        }

        let (errors, errorsObserver) = Signal<MessagesProviderError, NoError>.pipe()

        let newMessages = Signal<FirebaseEntity<Message>, NoError> { (observer, lifetime) in
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
                    errorsObserver.send(value: .wrapped(error))
                }
            }

            lifetime.observeEnded {
                reference.removeObserver(withHandle: handle)
            }
        }
            .map { [$0] }

        let cursor = MutableProperty<FirebaseEntity<Message>?>(nil)
        let isLoadingMore = MutableProperty<Bool>(false)

        let paginatedMessages = loadMoreMessages
            .observe(on: self.scheduler)
            .withLatest(from: cursor.producer)
            .filterMap { $1 }
            .flatMap(.concurrent(limit: 1)) { cursor -> SignalProducer<[FirebaseEntity<Message>], NoError> in
                isLoadingMore.value = true
                return loadMessageEntitiesOnce(limit: DefaultMessagesBatchCount, cursor: cursor)
                    .flatMapError { error -> SignalProducer<[FirebaseEntity<Message>], NoError> in
                        errorsObserver.send(value: error)
                        return .empty
                    }
                    .on(completed: { isLoadingMore.value = false })
            }

        let messages = Signal<[FirebaseEntity<Message>], NoError>.merge([newMessages, paginatedMessages])
            .observe(on: self.scheduler)
            .scan([FirebaseEntity<Message>]()) { (accum, messageEntities) in
                var mergedResult = messageEntities
                var ids = Set<String>()
                messageEntities.forEach { ids.insert($0.identifier) }

                accum.forEach { message in
                    if !ids.contains(message.identifier) {
                        ids.insert(message.identifier)
                        mergedResult.append(message)
                    }
                }

                return mergedResult
                    .sorted(by: { $0.model.date < $1.model.date })
            }
            .on(value: { messages in
                cursor.value = messages.first
            })

        let messagesProperty = Property(initial: [], then: messages)

        return MessagesResult(messages: messagesProperty, isLoadingMore: isLoadingMore.map { $0 }, errors: errors)
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
