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

    init(chatsProvider: ChatsProvider = .shared) {
        let (joinChatIdentifier, joinChatIdentifierObserver) = Signal<String, NoError>.pipe()
        let (chatsProviderErrors, chatsProviderErrorsObserver) = Signal<ChatsProviderError, NoError>.pipe()
        let (selectedItemIndex, selectedItemIndexObserver) = Signal<Int, NoError>.pipe()
        let (leaveItemIndex, leaveItemIndexObserver) = Signal<Int, NoError>.pipe()
        let (createChat, createChatObserver) = Signal<String, NoError>.pipe()

        let createdChatIdentifier = createChat
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .flatMap(.concat) { chatName in
                return chatsProvider.createChat(name: chatName)
                    .flatMapError { error -> SignalProducer<FirebaseEntity<Chat>, NoError> in
                        chatsProviderErrorsObserver.send(value: error)
                        return .empty
                }
            }
            .map { $0.identifier }

        let joinedChat = Signal.merge([joinChatIdentifier, createdChatIdentifier])
            .flatMap(.concat) { identifier -> SignalProducer<Void, NoError> in
                return chatsProvider.joinChat(identifier: identifier)
                    .flatMapError { error in
                        chatsProviderErrorsObserver.send(value: error)
                        return .empty
                    }
            }

        let (_leftChat, _leftChatObserver) = Signal<Void, NoError>.pipe()

        let chatEntities = chatsProvider.fetchChats(reload: Signal.merge([joinedChat, _leftChat]))

        let leftChat = leaveItemIndex
            .withLatest(from: chatEntities.producer)
            .map { $1[$0] }
            .flatMap(.concat) { chatEntity in
                return chatsProvider.leaveChat(chatEntity: chatEntity)
                    .flatMapError { error -> SignalProducer<Void, NoError> in
                        chatsProviderErrorsObserver.send(value: error)
                        return .empty
                    }
            }
            .on(value: _leftChatObserver.send)

        let items = chatEntities
            .map { chatEntities -> [ChatsViewItem] in
                guard chatEntities.isEmpty == false else {
                    return [ChatsViewItem.info(title: "No chats here yet", message: "In order to start a conversation you need to create a chat or ask your friend to send you a link")]
                }

                return chatEntities.map { chatEntity -> ChatsViewItem in
                    let title = chatEntity.model.name
                    let subtitle = chatEntity.model.lastMessage.map { "\($0.sender.name): \($0.body)" } ?? "No messages yet"
                    return .chat(title: title, subtitle: subtitle)
                }
            }

        let showErrorAlert = chatsProviderErrors
            .map { error -> (String, String) in
                let title = "Couldn't join chat"
                let message: String
                switch error {
                case .chatAlreadyAdded:
                    message = "Chat is already in list"
                case .chatNotFound:
                    message = "Chat doesn't exist"
                case .wrapped(let error):
                    message = error.localizedDescription
                }

                return (title, message)
            }

        let showChat = selectedItemIndex
            .withLatest(from: chatEntities.producer)
            .filterMap { (index, chatEntities) -> FirebaseEntity<Chat>? in
                guard chatEntities.isEmpty == false else {
                    return nil
                }

                return chatEntities[index]
            }

        self.items = items
        self.showErrorAlert = showErrorAlert
        self.showChat = showChat
        self.leftChat = leftChat
        self.joinChatIdentifierObserver = joinChatIdentifierObserver
        self.selectedItemIndexObserver = selectedItemIndexObserver
        self.leaveItemIndexObserver = leaveItemIndexObserver
        self.createChatObserver = createChatObserver
    }
}
