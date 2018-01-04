//
//  ChatViewController.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import UIKit
import MessageKit
import FirebaseDatabase
import RxSwift

class ChatViewController: MessagesViewController {
    private let disposeBag = DisposeBag()
    private let messagesProvider = MessagesProvider(database: Database.database())
    private let chatEntity: FirebaseEntity<Chat>
    private var messageEntities: [FirebaseEntity<Message>] = []

    init(chatEntity: FirebaseEntity<Chat>) {
        self.chatEntity = chatEntity
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = chatEntity.model.name
        self.messagesCollectionView.messagesDisplayDelegate = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDataSource = self
        self.messageInputBar.delegate = self

        setupBindings()
    }

    private func setupBindings() {
        messagesProvider.fetchMessageEntities(chatEntity: chatEntity, reloadMessages: Observable.just(()), loadMoreMessages: Observable.never())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] messageEntities in
                self?.messageEntities = messageEntities
                self?.messagesCollectionView.reloadData()
                self?.messagesCollectionView.scrollToBottom(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: "321", displayName: "312413")
    }

    func isFromCurrentSender(message: MessageType) -> Bool {
        return true
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        let entity = messageEntities[indexPath.section]
        return MessageWrapper(entity: entity)
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageEntities.count
    }
}

extension ChatViewController: MessagesLayoutDelegate {
    
}

extension ChatViewController: MessagesDisplayDelegate {
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return MessageStyle.bubbleTail(MessageStyle.TailCorner.bottomRight, MessageStyle.TailStyle.pointedEdge)
    }
}

private struct MessageWrapper: MessageType {
    let entity: FirebaseEntity<Message>

    var sender: Sender {
        return Sender(id: "123", displayName: "3121")
    }

    var messageId: String {
        return entity.identifier
    }

    var sentDate: Date {
        return entity.model.date
    }

    var data: MessageData {
        return .text(entity.model.body)
    }
}

extension ChatViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let message = Message(body: text, date: Date())

        messagesProvider.post(message: message, to: chatEntity)
            .subscribe(onError: { [weak self] error in
                self?.showAlert(for: error)
            })
            .disposed(by: disposeBag)
    }
}
