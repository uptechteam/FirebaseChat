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

    init(messagesProvider: MessagesProvider, chatEntity: FirebaseEntity<Chat>) {
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

        let messages = messagesProvider.fetchMessageEntities(chatEntity: chatEntity, loadMoreMessages: Signal<Void, NoError>.never)
        let items = messages
            .map { messages -> [ChatViewItem] in
                return messages.map { message in
                    let content = ChatViewMessageContent(body: message.model.body, isCurrentSender: false)
                    return ChatViewItem.message(content)
                }
            }

        let clearInputText = inputText.signal
            .sample(on: sendButtonTap)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .flatMap(.latest) { (text) -> SignalProducer<Void, NoError> in
                let message = Message(body: text, date: Date())
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
