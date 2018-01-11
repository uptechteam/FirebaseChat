//
//  ChatViewModel.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import ReactiveSwift
import ReactiveCocoa
import Result

final class ChatViewModel {
    let items: Property<[ChatViewItem]>
    let clearInputText: Signal<Void, NoError>

    let inputTextChangesObserver: Signal<String, NoError>.Observer
    let sendButtonTapObserver: Signal<Void, NoError>.Observer

    init(messagesProvider: MessagesProvider, userProvider: UserProvider, chatEntity: FirebaseEntity<Chat>) {
        let (inputTextChanges, inputTextChangesObserver) = Signal<String, NoError>.pipe()
        let (sendButtonTap, sendButtonTapObserver) = Signal<Void, NoError>.pipe()

        let (_clearInputText, _clearInputTextObserver) = Signal<Void, NoError>.pipe()
        let inputText = Property<String>(
            initial: "",
            then: Signal.merge([
                inputTextChanges,
                _clearInputText.map { _ in "" }
            ])
        )

        let currentUser = userProvider.currentUser

        let messages = messagesProvider.fetchMessageEntities(chatEntity: chatEntity, loadMoreMessages: Signal<Void, NoError>.never)
        let items = messages
            .combineLatest(with: currentUser)
            .map { (messages, currentUser) -> [ChatViewItem] in
                return messages.map { message in
                    let body = message.model.body
                    let isCurrentSender = message.model.sender == currentUser
                    let content = ChatViewMessageContent(body: body, isCurrentSender: isCurrentSender)
                    return ChatViewItem.message(content)
                }
            }

        let clearInputText = inputText.signal
            .sample(on: sendButtonTap)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .withLatest(from: currentUser.producer)
            .flatMap(.latest) { (text, currentUser) -> SignalProducer<Void, NoError> in
                let message = Message(body: text, date: Date(), sender: currentUser)
                return messagesProvider.post(message: message, to: chatEntity)
                    .flatMapError { _ in SignalProducer<Void, NoError>.empty }
            }
            .on(value: _clearInputTextObserver.send)

        self.items = items
        self.clearInputText = clearInputText
        self.inputTextChangesObserver = inputTextChangesObserver
        self.sendButtonTapObserver = sendButtonTapObserver
    }
}
