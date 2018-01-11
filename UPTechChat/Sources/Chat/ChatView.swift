//
//  ChatView.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import Result
import ReactiveCocoa
import ReactiveSwift

final class ChatView: UIView {
    var collectionViewLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var chatInputView: ChatInputView!
    @IBOutlet weak var chatInputViewBottomConstraint: NSLayoutConstraint!

    fileprivate let dataSource = ChatDataSource()

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        collectionView.transform = CGAffineTransform(scaleX: -1, y: -1)
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .none
        collectionView.showsVerticalScrollIndicator = false
        dataSource.set(collectionView: collectionView)
        updateContentInset(keyboardHeight: 0)

        let tapGestureRecognizer = UITapGestureRecognizer()
        collectionView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.reactive.stateChanged
            .take(duringLifetimeOf: self.reactive.lifetime)
            .filter { $0.state == .recognized }
            .observeValues { [weak self] _ in
                self?.endEditing(false)
            }

        let keyboardWillHide = NotificationCenter.default.reactive.notifications(forName: Notification.Name.UIKeyboardWillHide)
        let keyboardWillShow = NotificationCenter.default.reactive.notifications(forName: Notification.Name.UIKeyboardWillShow)

        Signal.merge([
            keyboardWillShow.map { ($0, true) },
            keyboardWillHide.map { ($0, false) }
        ])
            .take(duringLifetimeOf: self.reactive.lifetime)
            .observeValues { [weak self] (notification, isShow) in
                let userInfo = notification.userInfo!
                let animationCurve = UIViewAnimationCurve(rawValue: (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!
                let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
                let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect

                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationCurve(animationCurve)
                UIView.setAnimationDuration(animationDuration)
                self?.updateContentInset(keyboardHeight: isShow ? keyboardFrame.height : 0)
                UIView.commitAnimations()
            }
    }

    private func updateContentInset(keyboardHeight: CGFloat) {
        collectionView.contentInset = UIEdgeInsets(top: keyboardHeight + chatInputView.frame.height, left: 0, bottom: 0, right: 0)
        if collectionView.contentOffset.y <= chatInputView.frame.height {
            collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: -chatInputView.frame.height - keyboardHeight)
        }
        chatInputViewBottomConstraint.constant = keyboardHeight
        self.layoutIfNeeded()
    }
}

extension Reactive where Base: ChatView {
    var inputTextChanges: Signal<String, NoError> {
        return base.chatInputView.reactive.inputTextChanges
    }

    var sendButtonTap: Signal<Void, NoError> {
        return base.chatInputView.reactive.sendButtonTap
    }

    var scrolledToTop: Signal<Void, NoError> {
        return base.collectionView.reactive.signal(forKeyPath: #keyPath(UIScrollView.contentOffset))
            .filterMap { $0 as? CGPoint }
            .filter { [weak base] point -> Bool in
                guard let base = base else { return false }
                let delta = base.collectionView.contentSize.height - point.y - base.collectionView.frame.height
                return delta < 200
            }
            .map { _ in () }
    }

    var items: BindingTarget<[ChatViewItem]> {
        return BindingTarget(on: QueueScheduler.messages, lifetime: self.lifetime) { [weak base] items in
            base?.dataSource.load(items: items)
        }
    }

    var clearInputText: BindingTarget<Void> {
        return base.chatInputView.reactive.clearInputText
    }
}

extension ChatView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch dataSource.items[indexPath.row] {
        case .loading:
            return CGSize(width: collectionView.frame.width, height: 60)
        case .header:
            return CGSize(width: collectionView.frame.width, height: 40)
        case .message(let content):
            return CGSize(width: collectionView.frame.width, height: ChatViewMessageCell.preferredHeight(content: content, collectionViewFrame: collectionView.frame))
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    }
}
