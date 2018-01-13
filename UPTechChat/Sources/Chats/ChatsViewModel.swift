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

    let addChatIdentifierObserver: Signal<String, NoError>.Observer
    let selectedItemIndexObserver: Signal<Int, NoError>.Observer

    init(chatsProvider: ChatsProvider) {
        let (addChatIdentifier, addChatIdentifierObserver) = Signal<String, NoError>.pipe()
        let (chatsProviderErrors, chatsProviderErrorsObserver) = Signal<ChatsProviderError, NoError>.pipe()
        let (selectedItemIndex, selectedItemIndexObserver) = Signal<Int, NoError>.pipe()

        let chatAdded = addChatIdentifier
            .flatMap(.concat) { identifier -> SignalProducer<Void, NoError> in
                return chatsProvider.addChat(identifier: identifier)
                    .flatMapError { error in
                        chatsProviderErrorsObserver.send(value: error)
                        return .empty
                    }
            }

        let chatEntities = chatsProvider.fetchChats(reload: chatAdded)

        let items = chatEntities
            .map { chatEntities -> [ChatsViewItem] in
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
            .map { $1[$0] }

        self.items = items
        self.showErrorAlert = showErrorAlert
        self.showChat = showChat
        self.addChatIdentifierObserver = addChatIdentifierObserver
        self.selectedItemIndexObserver = selectedItemIndexObserver
    }
}
