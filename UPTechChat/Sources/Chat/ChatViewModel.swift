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

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d, h:mm a"
    return dateFormatter
}()

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
                let splittedMessages = splitMessages(messages)

                let items = splittedMessages.flatMap { dateGroup -> [ChatViewItem] in
                    let messageItems = dateGroup.senderGroups.flatMap { senderGroup -> [ChatViewItem] in
                        return senderGroup.messages.enumerated().map { (senderGroupIndex, message) -> ChatViewItem in
                            let isCurrentSender = message.model.sender == currentUser
                            let content = ChatViewMessageContent(
                                title: !isCurrentSender && senderGroupIndex == 0 ? message.model.sender.name : nil,
                                body: message.model.body,
                                isCurrentSender: isCurrentSender,
                                isCrooked: senderGroupIndex == senderGroup.messages.count - 1
                            )

                            return .message(content)
                        }
                    }

                    let headerItem = ChatViewItem.header(dateFormatter.string(from: dateGroup.date))

                    return [headerItem] + messageItems
                }

                return items
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

private struct DateGroup {
    let date: Date
    var senderGroups: [SenderGroup]
}

private struct SenderGroup {
    let sender: User
    var messages: [FirebaseEntity<Message>]
}

private func splitMessages(_ messages: [FirebaseEntity<Message>]) -> [DateGroup] {
    var dateGroups = [DateGroup]()
    messages.forEach { (message) in
        if let previousMessage = dateGroups.last?.senderGroups.last?.messages.last {
            if message.model.date.timeIntervalSince(previousMessage.model.date) > 300 {
                let newDateGroup = DateGroup(date: message.model.date, senderGroups: [SenderGroup(sender: message.model.sender, messages: [message])])
                dateGroups.append(newDateGroup)
            } else {
                var senderGroups = dateGroups[dateGroups.count - 1].senderGroups
                if previousMessage.model.sender != message.model.sender {
                    let newGroup = SenderGroup(sender: message.model.sender, messages: [message])
                    senderGroups.append(newGroup)
                } else {
                    senderGroups[senderGroups.count - 1].messages.append(message)
                }
                dateGroups[dateGroups.count - 1].senderGroups = senderGroups
            }
        } else {
            dateGroups = [DateGroup(
                date: message.model.date,
                senderGroups: [SenderGroup(
                    sender: message.model.sender,
                    messages: [message]
                )]
            )]
        }
    }

    return dateGroups
}
