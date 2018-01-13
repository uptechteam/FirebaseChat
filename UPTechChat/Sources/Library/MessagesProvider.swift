//
//  MessagesProvider.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import Foundation
import FirebaseDatabase
import ObjectMapper
import ReactiveSwift
import Result

private let DefaultMessagesBatchCount = 40

enum MessagesProviderError: Swift.Error {
    case wrapped(Swift.Error)
}

struct MessagesResult {
    let messages: Property<[FirebaseEntity<Message>]>
    let isLoadingMore: Property<Bool>
    let errors: Signal<MessagesProviderError, NoError>
}

final class MessagesProvider {
    static let shared = MessagesProvider()

    private let database: Database
    private let scheduler: QueueScheduler

    init(database: Database = .database(), scheduler: QueueScheduler = .messages) {
        self.database = database
        self.scheduler = scheduler
    }

    func fetchMessageEntities(
        chatEntity: FirebaseEntity<Chat>,
        loadMoreMessages: Signal<Void, NoError>
        ) -> LoadableProperty<[FirebaseEntity<Message>], MessagesProviderError> {

        let reference = database.reference(withPath: "messages/\(chatEntity.identifier)")
        let (errors, errorsObserver) = Signal<MessagesProviderError, NoError>.pipe()

        /// Emmits message entities once, limiting count to `limit` and paginating to `cursor`s max date
        func fetchMessageEntitiesOnce(limit: Int, cursor: FirebaseEntity<Message>?) -> SignalProducer<[FirebaseEntity<Message>], MessagesProviderError> {

            let query: DatabaseQuery = {
                let q1 = reference.queryOrdered(byChild: "date")

                // If cursor is not nil, add ending predicate
                let q2 = cursor.map { q1.queryEnding(atValue: $0.model.date.timeIntervalSince1970, childKey: "date") } ?? q1

                // Firebase duplicates cursor in response, so we increase limit by one to keep number of messages true
                let limit = cursor != nil ? limit + 1 : limit
                let q3 = q2.queryLimited(toLast: UInt(limit))

                return q3
            }()

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
                            .sorted(by: { $0.model.date.timeIntervalSince1970 < $1.model.date.timeIntervalSince1970 })

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
                .map { messages in
                    // If cursor is not nil drop last message to avoid duplicates
                    return cursor != nil ? Array(messages.dropLast()) : messages
                }
        }

        /// Emmits all observed messages with min `cursor`s date.
        func observeNewMessageEntities(cursor: FirebaseEntity<Message>?) -> SignalProducer<FirebaseEntity<Message>, NoError> {
            let query: DatabaseQuery = {
                let q1 = reference.queryOrdered(byChild: "date")

                let q2 = cursor.map { q1.queryStarting(atValue: $0.model.date.timeIntervalSince1970, childKey: "date") } ?? q1

                return q2
            }()

            return SignalProducer<FirebaseEntity<Message>, NoError> { observer, lifetime in
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
        }

        let paginationCursor = MutableProperty<FirebaseEntity<Message>?>(nil)
        let isLoadingMore = MutableProperty<Bool>(false)
        let isReachedEnd = MutableProperty<Bool>(false)

        let paginatedMessagesFlow = SignalProducer(loadMoreMessages)
            .prefix(value: ())
            .observe(on: scheduler)
            .withLatest(from: isLoadingMore)
            .filter { $1 == false }
            .withLatest(from: isReachedEnd.producer)
            .filter { $1 == false }
            .withLatest(from: paginationCursor.producer)
            .map { $1 }
            .flatMap(.latest) { cursor -> SignalProducer<[FirebaseEntity<Message>], NoError> in
                isLoadingMore.value = true
                return fetchMessageEntitiesOnce(limit: DefaultMessagesBatchCount, cursor: cursor)
                    .flatMapError { error -> SignalProducer<[FirebaseEntity<Message>], NoError> in
                        errorsObserver.send(value: error)
                        return .empty
                    }
                    .on(
                        completed: {
                            isLoadingMore.value = false
                        },
                        value: { messages in
                            if messages.count < DefaultMessagesBatchCount {
                                isReachedEnd.value = true
                            }
                        }
                    )
            }
            .scan([FirebaseEntity<Message>]()) { $1 + $0 }
            .on(value: { messages in
                paginationCursor.value = messages.first
            })

        let paginatedMessages = Property<[FirebaseEntity<Message>]?>(initial: nil, then: paginatedMessagesFlow)

        let newMessagesFlow = paginatedMessages.producer
            .filterMap { $0 }
            .take(first: 1)
            .flatMap(.latest) { paginatedMessages -> SignalProducer<FirebaseEntity<Message>, NoError> in
                let cursor = paginatedMessages.last
                return observeNewMessageEntities(cursor: cursor)
            }
            .map { [$0] }
            .scan([FirebaseEntity<Message>]()) { $0 + $1 }

        let newMessages = Property<[FirebaseEntity<Message>]?>(initial: nil, then: newMessagesFlow)

        let messages = Property.combineLatest(paginatedMessages, newMessages)
            .map { (paginatedMessagesOrNil, newMessagesOrNil) -> [FirebaseEntity<Message>]? in
                return paginatedMessagesOrNil.map { paginatedMessages in
                    return paginatedMessages + (newMessagesOrNil ?? [])
                }
            }

        return LoadableProperty(property: messages, isLoading: isLoadingMore.map { $0 }, errors: errors)
    }

    func post(message: Message, to chatEntity: FirebaseEntity<Chat>) -> SignalProducer<Void, MessagesProviderError> {
        func updateChatEntity() -> SignalProducer<Void, MessagesProviderError> {
            let reference = self.database.reference(withPath: "chats/\(chatEntity.identifier)/lastMessage")
            return SignalProducer { observer, lifetime in
                let json = Mapper<Message>().toJSON(message)
                reference.setValue(json) { error, _ in
                    if let error = error {
                        observer.send(error: .wrapped(error))
                    } else {
                        observer.send(value: ())
                        observer.sendCompleted()
                    }
                }
            }
        }

        func postMessage() -> SignalProducer<Void, MessagesProviderError> {
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

        return SignalProducer.zip(updateChatEntity(), postMessage())
            .map { _ in () }
    }
}
