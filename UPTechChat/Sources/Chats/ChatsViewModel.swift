//
//  ChatsViewModel.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/12/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import ReactiveSwift
import Result

final class ChatsViewModel {
    let items: Property<[ChatsViewItem]>
    let showErrorAlert: Signal<(String, String), NoError>
    let showChat: Signal<FirebaseEntity<Chat>, NoError>
    let leftChat: Signal<Void, NoError>

    let joinChatIdentifierObserver: Signal<String, NoError>.Observer
    let selectedItemIndexObserver: Signal<Int, NoError>.Observer
    let leaveItemIndexObserver: Signal<Int, NoError>.Observer
    let createChatObserver: Signal<String, NoError>.Observer

    init(chatsProvider: ChatsProvider = .shared, scheduler: QueueScheduler = .main) {
        let (joinChatIdentifier, joinChatIdentifierObserver) = Signal<String, NoError>.pipe()
        let (selectedItemIndex, selectedItemIndexObserver) = Signal<Int, NoError>.pipe()
        let (leaveItemIndex, leaveItemIndexObserver) = Signal<Int, NoError>.pipe()
        let (createChat, createChatObserver) = Signal<String, NoError>.pipe()

        let isCreatingChat = MutableProperty(false)
        let (chatCreationErrors, chatCreationErrorsObserver) = Signal<ChatsProviderError, NoError>.pipe()
        let createdChatIdentifier = createChat
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .flatMap(.concat) { chatName -> SignalProducer<FirebaseEntity<Chat>, NoError> in
                isCreatingChat.value = true
                return chatsProvider.createChat(name: chatName)
                    .flatMapError { error -> SignalProducer<FirebaseEntity<Chat>, NoError> in
                        chatCreationErrorsObserver.send(value: error)
                        return .empty
                    }
                    .on(completed: { isCreatingChat.value = false })
            }
            .map { $0.identifier }

        let isJoiningChat = MutableProperty(false)
        let (chatJoiningErrors, chatJoiningErrorsObserver) = Signal<ChatsProviderError, NoError>.pipe()
        let joinedChat = Signal.merge([joinChatIdentifier, createdChatIdentifier])
            .flatMap(.concat) { identifier -> SignalProducer<Void, NoError> in
                isJoiningChat.value = true
                return chatsProvider.joinChat(identifier: identifier)
                    .flatMapError { error in
                        chatJoiningErrorsObserver.send(value: error)
                        return .empty
                    }
                    .on(completed: { isJoiningChat.value = false })
            }

        let (_leftChat, _leftChatObserver) = Signal<Void, NoError>.pipe()

        let chatsLoadableProperty = chatsProvider.fetchChats(reload: Signal.merge([joinedChat, _leftChat]))
        let chatEntities = chatsLoadableProperty.property

        let isLeavingChat = MutableProperty(false)
        let (chatLeavingErrors, chatLeavingErrorsObserver) = Signal<ChatsProviderError, NoError>.pipe()
        let leftChat = leaveItemIndex
            .withLatest(from: chatEntities.producer)
            .filterMap { $1?[$0] }
            .flatMap(.concat) { chatEntity -> SignalProducer<Void, NoError> in
                isLeavingChat.value = true
                return chatsProvider.leaveChat(chatEntity: chatEntity)
                    .flatMapError { error -> SignalProducer<Void, NoError> in
                        chatLeavingErrorsObserver.send(value: error)
                        return .empty
                    }
                    .on(completed: { isLeavingChat.value = false })
            }
            .on(value: _leftChatObserver.send)

        let isLoadingFlow = SignalProducer.combineLatest([
            isCreatingChat.producer,
            isJoiningChat.producer,
            isLeavingChat.producer,
            chatsLoadableProperty.isLoading.producer
        ])
            .map { isLoadingArray in
                return isLoadingArray.reduce(false) { $0 || $1 }
            }
            .skipRepeats()
            .throttle(0.1, on: scheduler)
        
        let isLoading = Property(initial: false, then: isLoadingFlow)

        let itemsFlow = Property.combineLatest(chatEntities, isLoading).producer
            .map { (chatEntities, isLoading) -> [ChatsViewItem] in
                let chatItems: [ChatsViewItem] = {
                    guard let chatEntities = chatEntities else {
                        return []
                    }

                    if chatEntities.isEmpty && isLoading == false {
                        return [ChatsViewItem.info(title: "No chats here yet", message: "In order to start a conversation you need to create a chat or ask your friend to send you a link")]
                    }

                    return chatEntities.map { chatEntity -> ChatsViewItem in
                        let title = chatEntity.model.name
                        let subtitle = chatEntity.model.lastMessage.map { "\($0.sender.name): \($0.text ?? "")" } ?? "No messages yet"
                        return .chat(title: title, subtitle: subtitle)
                    }
                }()

                let loadingItems: [ChatsViewItem] = isLoading ? [.loading] : []

                return loadingItems + chatItems
            }

        let showErrorAlert = Signal.merge([
            chatCreationErrors.map { ("Couldn't create chat", $0) },
            chatJoiningErrors.map { ("Couldn't join chat", $0) },
            chatLeavingErrors.map { ("Couldn't leave chat", $0) }
        ])
            .map { (errorReason, error) -> (String, String) in
                let message: String
                switch error {
                case .chatAlreadyAdded:
                    message = "Chat is already in list"
                case .chatNotFound:
                    message = "Chat doesn't exist"
                case .wrapped(let error):
                    message = error.localizedDescription
                }

                return (errorReason, message)
            }

        let showChat = selectedItemIndex
            .withLatest(from: chatEntities.producer)
            .filterMap { (index, chatEntities) -> FirebaseEntity<Chat>? in
                guard let chatEntities = chatEntities, chatEntities.isEmpty == false else {
                    return nil
                }

                return chatEntities[index]
            }

        self.items = Property(initial: [], then: itemsFlow)
        self.showErrorAlert = showErrorAlert
        self.showChat = showChat
        self.leftChat = leftChat
        self.joinChatIdentifierObserver = joinChatIdentifierObserver
        self.selectedItemIndexObserver = selectedItemIndexObserver
        self.leaveItemIndexObserver = leaveItemIndexObserver
        self.createChatObserver = createChatObserver
    }
}
