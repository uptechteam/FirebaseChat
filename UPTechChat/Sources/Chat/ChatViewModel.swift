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
    // Outputs
    let items: Property<[ChatViewItem]>
    let title: Property<String>
    let clearInputText: Signal<Void, NoError>
    let messageSendRetried: Signal<Void, NoError>
    let showLastMessage: Signal<Void, NoError>
    let showUrlShareMenu: Signal<URL, NoError>

    // Inputs
    let inputTextChangesObserver: Signal<String, NoError>.Observer
    let sendButtonTapObserver: Signal<Void, NoError>.Observer
    let scrolledToTopObserver: Signal<Void, NoError>.Observer
    let shareMenuButtonTapObserver: Signal<Void, NoError>.Observer
    let retryTapObserver: Signal<Int, NoError>.Observer

    init(messagesProvider: MessagesProvider = .shared,
         userProvider: UserProvider = .shared,
         scheduler: QueueScheduler = .messages,
         chatEntity: FirebaseEntity<Chat>) {
        // Inputs
        let (inputTextChanges, inputTextChangesObserver) = Signal<String, NoError>.pipe()
        let (sendButtonTap, sendButtonTapObserver) = Signal<Void, NoError>.pipe()
        let (scrolledToTop, scrolledToTopObserver) = Signal<Void, NoError>.pipe()
        let (shareMenuButtonTap, shareMenuButtonTapObserver) = Signal<Void, NoError>.pipe()
        let (retryTap, retryTapObserver) = Signal<Int, NoError>.pipe()

        // Forward reference to `clearInputText`
        // Events from `clearInputText` sent to this observer
        let (_clearInputText, _clearInputTextObserver) = Signal<Void, NoError>.pipe()

        let inputText = Property<String>(
            initial: "",
            then: Signal.merge([
                inputTextChanges,
                _clearInputText.map { _ in "" }
            ])
        )

        let currentUser = userProvider.currentUser

        // All messages that are already sent or will be sent
        let newLocalMessages = sendButtonTap
            .withLatest(from: inputText.producer)
            .map { $1 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .withLatest(from: currentUser.producer)
            .map { Message(body: $0, date: Date(), sender: $1) }

        // Forward reference to `messageSendRetried`
        let (retriedLocalMessages, retriedLocalMessagesObserver) = Signal<Message, NoError>.pipe()

        let localMessages = Signal.merge([newLocalMessages, retriedLocalMessages])

        // Clear input text after adding new message
        let clearInputText = localMessages
            .map { _ in () }
            .on(value: _clearInputTextObserver.send)

        // Show last message after adding new message
        let showLastMessage = localMessages
            .map { _ in () }

        // Local messages
        let localMessageStatusesFlow = localMessages
            .flatMap(.merge) { message -> SignalProducer<(Message, LocalMessageStatus), NoError> in
                let status = messagesProvider.post(message: message, to: chatEntity)
                    .map { LocalMessageStatus.sent }
                    .flatMapError { error in SignalProducer<LocalMessageStatus, NoError>(value: .failed(error)) }
                    .prefix(value: .pending)

                return status.map { (message, $0) }
            }

        let localMessageStatusesDictionary = localMessageStatusesFlow
            .scan([Message: LocalMessageStatus]()) { accum, args in
                let (message, messageStatus) = args

                var accum = accum
                accum[message] = messageStatus
                return accum
            }
        let localMessageStatuses = Property(initial: [:], then: localMessageStatusesDictionary)

        // Remote messages
        let messagesLoadableProperty = messagesProvider.fetchMessageEntities(chatEntity: chatEntity, loadMoreMessages: scrolledToTop)
        let remoteMessages = messagesLoadableProperty.property.map { $0 ?? [] }

        // All messages
        let allMessages = Property.combineLatest(localMessageStatuses, remoteMessages)
            .map { (localMessageStatuses, remoteMessages) -> [InternalMessage] in
                // Due to FirebaseDatabase working logic, MessagesProvider can return local message
                // in messages batch faster than local message becomes sent.
                // We filter out pending messages out of remote messages to avoid duplicates.
                let remoteMessagesWithoutPending = remoteMessages
                    .filter { remoteMessage in
                        if let localStatus = localMessageStatuses[remoteMessage.model], case .pending = localStatus {
                            return false
                        }

                        return true
                    }

                // We leave pending and failed messages to be displayed only.
                // Suppose that sent messages were received from `MessagesProvider` already.
                let pendingOrFailedLocalMessages = localMessageStatuses
                    .filter { (_: Message, messageStatus: LocalMessageStatus) -> Bool in
                        switch messageStatus {
                        case .pending, .failed:
                            return true
                        case .sent:
                            return false
                        }
                    }
                    .sorted(by: { (lhs: (Message, LocalMessageStatus), rhs: (Message, LocalMessageStatus)) -> Bool in
                        return lhs.0.date.timeIntervalSince1970 < rhs.0.date.timeIntervalSince1970
                    })

                // Display remote messages without pending and then pending or failed local messages
                let allMessages = remoteMessagesWithoutPending.map(InternalMessage.remote) + pendingOrFailedLocalMessages.map(InternalMessage.local)

                return allMessages
            }

        // Internal layout
        // We split chat layout to internal and view to incapsulate
        // layouting logic inside of view model.
        let internalLayoutProducer = SignalProducer.combineLatest(
            allMessages.producer,
            messagesLoadableProperty.isLoading.producer,
            currentUser.producer
        )
            .throttle(0.01, on: scheduler)
            .map(makeInternalLayout)
        let internalLayout = Property(initial: [], then: internalLayoutProducer)

        // View layout
        let viewLayout = internalLayout
            .map(makeViewLayout)

        // Use internal layout to get message that should be retried to send
        let messageSendRetried = retryTap
            .withLatest(from: internalLayout.producer)
            .filterMap { (index, layout) -> Message? in
                let layoutItem = layout[index]

                switch layoutItem {
                case .message(let message, _, _, _):
                    return message.model
                default:
                    return nil
                }
            }
            .on(value: retriedLocalMessagesObserver.send)
            .map { _ in () }

        // Make deep linking url for chat invitation
        let showUrlShareMenu = shareMenuButtonTap
            .filterMap { () -> URL? in
                return URL(string: "uptechchat://join/\(chatEntity.identifier)")
            }

        // Properties
        self.items = viewLayout
        self.title = Property(value: chatEntity.model.name)
        self.clearInputText = clearInputText
        self.messageSendRetried = messageSendRetried
        self.showLastMessage = showLastMessage
        self.showUrlShareMenu = showUrlShareMenu
        self.inputTextChangesObserver = inputTextChangesObserver
        self.sendButtonTapObserver = sendButtonTapObserver
        self.scrolledToTopObserver = scrolledToTopObserver
        self.shareMenuButtonTapObserver = shareMenuButtonTapObserver
        self.retryTapObserver = retryTapObserver
    }
}

private enum LocalMessageStatus {
    // Messages in process of sending
    case pending

    // Messages failed to be sent with error
    case failed(Swift.Error)

    // Sent messages
    case sent
}

private enum InternalMessage {
    // Messages created locally.
    case local(Message, LocalMessageStatus)

    // Messages received from `MessagesProvider`.
    case remote(FirebaseEntity<Message>)

    var model: Message {
        switch self {
        case let .local(message, _):
            return message
        case .remote(let entity):
            return entity.model
        }
    }
}

// Represents view model internal chat layout item
private enum InternalLayoutItem {
    case loading
    case dateHeader(Date)
    case noMessagesHeader
    case message(message: InternalMessage, isCurrentSender: Bool, isStartOfGroup: Bool, isEndOfGroup: Bool)
}

// Makes internal chat layout
private func makeInternalLayout(internalMessages: [InternalMessage], isLoading: Bool, currentUser: User) -> [InternalLayoutItem] {
    struct DateGroup {
        let date: Date
        var senderGroups: [SenderGroup]
    }

    struct SenderGroup {
        let sender: User
        var messages: [InternalMessage]
    }

    // Splits messages into groups
    func splitMessages(_ messages: [InternalMessage]) -> [DateGroup] {
        var dateGroups = [DateGroup]()
        messages.forEach { (message) in
            // Take previous added message
            if let previousMessage = dateGroups.last?.senderGroups.last?.messages.last {
                // If previous message date differs from current message date too much
                if message.model.date.timeIntervalSince(previousMessage.model.date) > 300 {
                    // Create a new date group
                    let newDateGroup = DateGroup(date: message.model.date, senderGroups: [SenderGroup(sender: message.model.sender, messages: [message])])
                    dateGroups.append(newDateGroup)
                } else {
                    // Take a last created date group
                    var senderGroups = dateGroups[dateGroups.count - 1].senderGroups
                    // If previous message sender differs from current message sender
                    if previousMessage.model.sender != message.model.sender {
                        // Create a new sender group
                        let newGroup = SenderGroup(sender: message.model.sender, messages: [message])
                        senderGroups.append(newGroup)
                    } else {
                        // Add message to last sender group
                        senderGroups[senderGroups.count - 1].messages.append(message)
                    }

                    dateGroups[dateGroups.count - 1].senderGroups = senderGroups
                }
            } else {
                // Add initial message
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

    // Messages
    let messageItems: [InternalLayoutItem] = {
        if internalMessages.isEmpty && isLoading == false {
            return [.noMessagesHeader]
        }

        // Converting message groups to internal layout
        // Adds titles and crooked bubbles to sender groups
        // Adds headers for date groups
        return splitMessages(internalMessages)
            .flatMap { dateGroup -> [InternalLayoutItem] in
                let messageItems = dateGroup.senderGroups.flatMap { senderGroup -> [InternalLayoutItem] in
                    return senderGroup.messages.enumerated().map { (senderGroupIndex, message) -> InternalLayoutItem in
                        return InternalLayoutItem.message(
                            message: message,
                            isCurrentSender: message.model.sender == currentUser,
                            isStartOfGroup: senderGroupIndex == 0,
                            isEndOfGroup: senderGroupIndex == senderGroup.messages.count - 1
                        )
                    }
                }

                let headerItem = InternalLayoutItem.dateHeader(dateGroup.date)

                return [headerItem] + messageItems
            }
    }()

    // Loading indicator
    let loadingItem: [InternalLayoutItem] = isLoading ? [.loading] : []

    return loadingItem + messageItems
}

// Converts viewModel's internal layout into view layout
private func makeViewLayout(internalLayout: [InternalLayoutItem]) -> [ChatViewItem] {
    return internalLayout.map { internalLayoutItem -> ChatViewItem in
        switch internalLayoutItem {
        case .loading:
            return .loading
        case .dateHeader(let date):
            return .header(makeDateHeaderTitle(for: date))
        case .noMessagesHeader:
            return .header("No messages yet")
        case let .message(message, isCurrentSender, isStartOfGroup, isEndOfGroup):
            let isFailed: Bool = {
                if case .local(_, let status) = message, case .failed = status {
                    return true
                }

                return false
            }()
            let content = ChatViewMessageContent(
                title: isStartOfGroup && !isCurrentSender ? message.model.sender.name : nil,
                body: message.model.body,
                isCurrentSender: isCurrentSender,
                isCrooked: isEndOfGroup,
                hiddenText: timeDateFormatter.string(from: message.model.date),
                statusText: isFailed ? "Not delivered" : nil,
                isRetryShown: isFailed
            )
            return .message(content)
        }
    }
}

private let defaultDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "E, MMM d"
    return dateFormatter
}()

private let weekDayDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE"
    return dateFormatter
}()

private let timeDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "h:mm a"
    return dateFormatter
}()

private func makeDateHeaderTitle(for date: Date) -> String {
    let calendar = Calendar.current
    let currentDate = Date()

    if calendar.isDateInToday(date) {
        // Today
        return "Today \(timeDateFormatter.string(from: date))"
    } else if calendar.isDateInYesterday(date) {
        // Yesterday
        return "Yesterday \(timeDateFormatter.string(from: date))"
    } else if
        calendar.isDate(date, equalTo: currentDate, toGranularity: Calendar.Component.weekOfYear) &&
        calendar.isDate(date, equalTo: currentDate, toGranularity: Calendar.Component.year)
    {
        // This week
        return "\(weekDayDateFormatter.string(from: date)) \(timeDateFormatter.string(from: date)))"
    } else {
        // Other cases
        return "\(defaultDateFormatter.string(from: date)), \(timeDateFormatter.string(from: date))"
    }
}
