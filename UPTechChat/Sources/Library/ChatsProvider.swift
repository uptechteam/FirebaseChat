//
//  ChatsProvider.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/13/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import FirebaseDatabase
import ReactiveSwift
import Result
import ObjectMapper

private let ChatsKey = "chats"

enum ChatsProviderError: LocalizedError {
    case chatAlreadyAdded
    case chatNotFound
    case wrapped(Swift.Error)
}

final class ChatsProvider {
    static let shared = ChatsProvider()

    private let database: Database
    private let userDefaults: UserDefaults

    init(database: Database = .database(), userDefaults: UserDefaults = .standard) {
        self.database = database
        self.userDefaults = userDefaults
    }

    func createChat(name: String) -> SignalProducer<FirebaseEntity<Chat>, ChatsProviderError> {
        return .init { observer, lifetime in
            let reference = self.database.reference(withPath: "chats").childByAutoId()
            let model = Chat(name: name, lastMessage: nil)
            reference.setValue(model.toJSON(), withCompletionBlock: { (error, reference) in
                if let error = error {
                    observer.send(error: .wrapped(error))
                } else {
                    let entity = FirebaseEntity<Chat>(identifier: reference.key, model: model)
                    observer.send(value: entity)
                    observer.sendCompleted()
                }
            })
        }
    }

    func joinChat(identifier: String) -> SignalProducer<Void, ChatsProviderError> {
        func isIdentifierValid() -> SignalProducer<Bool, NoError> {
            let reference = chatReference(identifier: identifier)
            return .init { observer, lifetime in
                reference.observeSingleEvent(of: .value) { snapshot in
                    do {
                        _ = try self.makeChatEntity(identifier: identifier, snapshot: snapshot)
                        observer.send(value: true)
                    } catch {
                        observer.send(value: false)
                    }
                }
            }
        }

        func isIdentifierAlreadyAdded() -> SignalProducer<Bool, NoError> {
            return .init { () -> Bool in
                let mutableArray = self.userDefaults.mutableArrayValue(forKey: ChatsKey)
                return mutableArray.flatMap { $0 as? String }.index(of: identifier) != nil
            }
        }

        func appendToUserDefaults() -> SignalProducer<Void, NoError> {
            return .init { () -> () in
                let mutableArray = self.userDefaults.mutableArrayValue(forKey: ChatsKey)
                mutableArray.add(identifier)
                self.userDefaults.synchronize()
                return ()
            }
        }

        return SignalProducer.zip(isIdentifierValid(), isIdentifierAlreadyAdded())
            .flatMap(.latest) { (isIdentifierValid, isIdentifierAlreadyAdded) -> SignalProducer<Void, ChatsProviderError> in
                guard isIdentifierAlreadyAdded == false else {
                    return SignalProducer(error: ChatsProviderError.chatAlreadyAdded)
                }

                guard isIdentifierValid else {
                    return SignalProducer(error: ChatsProviderError.chatNotFound)
                }

                return appendToUserDefaults()
                    .promoteError(ChatsProviderError.self)
            }
    }

    func leaveChat(chatEntity: FirebaseEntity<Chat>) -> SignalProducer<Void, ChatsProviderError> {
        return .init { () -> Result<Void, ChatsProviderError> in
            let mutableArray = self.userDefaults.mutableArrayValue(forKey: ChatsKey)
            let identifiers = mutableArray.flatMap { $0 as? String }
            guard let index = identifiers.index(of: chatEntity.identifier) else {
                return .failure(.chatNotFound)
            }
            mutableArray.removeObject(at: index)
            self.userDefaults.synchronize()
            return .success(())
        }
    }

    func fetchChats(reload: Signal<Void, NoError>) -> LoadableProperty<[FirebaseEntity<Chat>], ChatsProviderError> {
        func fetchChatIdentifiers() -> SignalProducer<[String], NoError> {
            return .init { () -> [String] in
                let mutableArray = self.userDefaults.mutableArrayValue(forKey: ChatsKey)
                return mutableArray.flatMap { $0 as? String }
            }
        }

        func observeFirebaseChatEntity(identifier: String) -> SignalProducer<FirebaseEntity<Chat>, ChatsProviderError> {
            let reference = chatReference(identifier: identifier)
            return SignalProducer { observer, lifetime in
                let handle = reference.observe(.value) { snapshot in
                    do {
                        let entity = try self.makeChatEntity(identifier: identifier, snapshot: snapshot)
                        observer.send(value: entity)
                    } catch {
                        observer.send(error: .wrapped(error))
                    }
                }

                lifetime.observeEnded {
                    reference.removeObserver(withHandle: handle)
                }
            }
        }

        let (errors, errorsObserver) = Signal<ChatsProviderError, NoError>.pipe()

        let isLoading = MutableProperty(false)

        let chatsFlow = SignalProducer(reload)
            .prefix(value: ())
            .withLatest(from: isLoading)
            .filter { !$1 }
            .flatMap(.latest) { _ -> SignalProducer<[FirebaseEntity<Chat>], NoError> in
                isLoading.value = true
                return fetchChatIdentifiers()
                    .flatMap(.latest) { chatIdentifiers -> SignalProducer<[FirebaseEntity<Chat>], NoError> in
                        guard chatIdentifiers.isEmpty == false else {
                            return .init(value: [])
                        }

                        let deferredChatEntities = chatIdentifiers
                            .map { chatIdentifier -> SignalProducer<[FirebaseEntity<Chat>], NoError> in
                                return observeFirebaseChatEntity(identifier: chatIdentifier)
                                    .map { [$0] }
                                    .flatMapError { error in
                                        errorsObserver.send(value: error)
                                        return SignalProducer(value: [])
                                }
                            }

                        return SignalProducer.combineLatest(deferredChatEntities)
                            .map { $0.flatMap { $0 } }
                    }
                    .on(value: { _ in isLoading.value = false })
            }

        let chats = Property<[FirebaseEntity<Chat>]?>(initial: nil, then: chatsFlow)

        return LoadableProperty(property: chats, isLoading: isLoading.map { $0 }, errors: errors)
    }

    private func chatReference(identifier: String) -> DatabaseReference {
        return database.reference(withPath: "chats/\(identifier)")
    }

    private func makeChatEntity(identifier: String, snapshot: DataSnapshot) throws -> FirebaseEntity<Chat> {
        guard let value = snapshot.value else {
            throw ChatsProviderError.chatNotFound
        }

        do {
            let chat = try Mapper<Chat>().map(JSONObject: value)
            let entity = FirebaseEntity<Chat>(identifier: identifier, model: chat)
            return entity
        } catch {
            throw ChatsProviderError.wrapped(error)
        }
    }
}
