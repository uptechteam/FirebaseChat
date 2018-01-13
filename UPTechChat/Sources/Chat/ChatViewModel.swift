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

private let preciseTimeDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "h:mm a"
    return dateFormatter
}()

final class ChatViewModel {
    let items: Property<[ChatViewItem]>
    let title: Property<String>
    let clearInputText: Signal<Void, NoError>
    let showUrlShareMenu: Signal<URL, NoError>

    let inputTextChangesObserver: Signal<String, NoError>.Observer
    let sendButtonTapObserver: Signal<Void, NoError>.Observer
    let scrolledToTopObserver: Signal<Void, NoError>.Observer
    let shareMenuButtonTapObserver: Signal<Void, NoError>.Observer

    init(messagesProvider: MessagesProvider = .shared,
         userProvider: UserProvider = .shared,
         scheduler: QueueScheduler = .messages,
         chatEntity: FirebaseEntity<Chat>) {
        let (inputTextChanges, inputTextChangesObserver) = Signal<String, NoError>.pipe()
        let (sendButtonTap, sendButtonTapObserver) = Signal<Void, NoError>.pipe()
        let (scrolledToTop, scrolledToTopObserver) = Signal<Void, NoError>.pipe()
        let (shareMenuButtonTap, shareMenuButtonTapObserver) = Signal<Void, NoError>.pipe()

        let (_clearInputText, _clearInputTextObserver) = Signal<Void, NoError>.pipe()
        let inputText = Property<String>(
            initial: "",
            then: Signal.merge([
                inputTextChanges,
                _clearInputText.map { _ in "" }
            ])
        )

        let currentUser = userProvider.currentUser

        let messagesLoadableProperty = messagesProvider.fetchMessageEntities(chatEntity: chatEntity, loadMoreMessages: scrolledToTop)
        let itemsProducer = SignalProducer.combineLatest(
            messagesLoadableProperty.property.producer,
            messagesLoadableProperty.isLoading.producer,
            currentUser.producer
        )
            .throttle(0.2, on: scheduler)
            .map { (messages, isLoading, currentUser) -> [ChatViewItem] in
                let messageItems: [ChatViewItem] = {
                    guard let messages = messages else {
                        return []
                    }

                    guard messages.isEmpty == false else {
                        return [.header("No messages yet")]
                    }

                    return splitMessages(messages).flatMap { dateGroup -> [ChatViewItem] in
                        let messageItems = dateGroup.senderGroups.flatMap { senderGroup -> [ChatViewItem] in
                            return senderGroup.messages.enumerated().map { (senderGroupIndex, message) -> ChatViewItem in
                                let isCurrentSender = message.model.sender == currentUser
                                let content = ChatViewMessageContent(
                                    title: !isCurrentSender && senderGroupIndex == 0 ? message.model.sender.name : nil,
                                    body: message.model.body,
                                    isCurrentSender: isCurrentSender,
                                    isCrooked: senderGroupIndex == senderGroup.messages.count - 1,
                                    hiddenText: preciseTimeDateFormatter.string(from: message.model.date)
                                )

                                return .message(content)
                            }
                        }

                        let headerItem = ChatViewItem.header(dateFormatter.string(from: dateGroup.date))

                        return [headerItem] + messageItems
                    }
                }()

                let loadingItem: [ChatViewItem] = isLoading ? [.loading] : []

                return loadingItem + messageItems
            }

        let clearInputText = sendButtonTap
            .withLatest(from: inputText.producer)
            .map { $1 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .withLatest(from: currentUser.producer)
            .flatMap(.latest) { (text, currentUser) -> SignalProducer<Void, NoError> in
                let message = Message(body: text, date: Date(), sender: currentUser)
                return messagesProvider.post(message: message, to: chatEntity)
                    .flatMapError { _ in SignalProducer<Void, NoError>.empty }
            }
            .on(value: _clearInputTextObserver.send)

        let showUrlShareMenu = shareMenuButtonTap
            .filterMap { () -> URL? in
                return URL(string: "uptechchat://join/\(chatEntity.identifier)")
            }

        self.items = Property(initial: [], then: itemsProducer)
        self.title = Property(value: chatEntity.model.name)
        self.clearInputText = clearInputText
        self.showUrlShareMenu = showUrlShareMenu
        self.inputTextChangesObserver = inputTextChangesObserver
        self.sendButtonTapObserver = sendButtonTapObserver
        self.scrolledToTopObserver = scrolledToTopObserver
        self.shareMenuButtonTapObserver = shareMenuButtonTapObserver
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
