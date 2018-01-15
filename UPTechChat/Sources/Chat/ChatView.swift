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
    @IBOutlet weak var collectionView: ChatCollectionView!
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
        collectionView.allowsSelection = true
        collectionView.scrollsToTop = false
        dataSource.set(collectionView: collectionView)
        updateContentInset(previousKeyboardHeight: 0, keyboardHeight: 0)

        // Hiding keyboard with tap
        let tapGestureRecognizer = UITapGestureRecognizer()
        collectionView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.reactive.stateChanged
            .take(duringLifetimeOf: self.reactive.lifetime)
            .filter { $0.state == .recognized }
            .observeValues { [weak self] _ in
                self?.endEditing(false)
            }

        // Observing keyboard frame to keep content visible
        let keyboardWillHide = NotificationCenter.default.reactive.notifications(forName: Notification.Name.UIKeyboardWillHide)
        let keyboardWillShow = NotificationCenter.default.reactive.notifications(forName: Notification.Name.UIKeyboardWillShow)

        struct KeyboardChangeContext {
            let animationCurve: UIViewAnimationCurve
            let animationDuration: Double
            let keyboardHeight: CGFloat
        }

        Signal.merge([
            keyboardWillShow.map { ($0, true) },
            keyboardWillHide.map { ($0, false) }
        ])
            .take(duringLifetimeOf: self.reactive.lifetime)
            .map { (notification, isShow) -> KeyboardChangeContext in
                let userInfo = notification.userInfo!
                return KeyboardChangeContext(
                    animationCurve: UIViewAnimationCurve(rawValue: (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!,
                    animationDuration: userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double,
                    keyboardHeight: isShow ? (userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect).height : 0
                )
            }
            .map(Optional.init)
            .combinePrevious(nil)
            .observeValues { [weak self] (previousContext, context) in
                guard let context = context, let `self` = self else { return }

                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationCurve(context.animationCurve)
                UIView.setAnimationDuration(context.animationDuration)
                self.updateContentInset(
                    previousKeyboardHeight: previousContext?.keyboardHeight ?? 0,
                    keyboardHeight: context.keyboardHeight
                )
                UIView.commitAnimations()
            }
    }

    private func updateContentInset(previousKeyboardHeight: CGFloat, keyboardHeight: CGFloat) {
        // Updating contentInset can change contentOffset in some cases
        // Prevent this to update it manually later by restoring contentOffset to previous value after changing contentInset
        let temp = collectionView.contentOffset
        let topContentInset = keyboardHeight + chatInputView.frame.height
        collectionView.contentInset = UIEdgeInsets(top: topContentInset, left: 0, bottom: 0, right: 0)
        collectionView.contentOffset = temp

        // Scroll collectionView by keyboard height delta to keep content visible
        let keyboardHeightDelta = previousKeyboardHeight - keyboardHeight
        let minContentOffset = -topContentInset
        let maxContentOffset = max(-topContentInset, collectionView.contentSize.height - collectionView.frame.height)
        let newContentOffset = min(maxContentOffset, max(minContentOffset, collectionView.contentOffset.y + keyboardHeightDelta))
        collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: newContentOffset)

        // Move ChatInputView to keep it above keyboard
        chatInputViewBottomConstraint.constant = keyboardHeight
        self.layoutIfNeeded()
    }
}

extension Reactive where Base: ChatView {
    // Outputs
    var inputTextChanges: Signal<String, NoError> {
        return base.chatInputView.reactive.inputTextChanges
    }

    var sendButtonTap: Signal<Void, NoError> {
        return base.chatInputView.reactive.sendButtonTap
    }

    var addAttachmentButtonTap: Signal<Void, NoError> {
        return base.chatInputView.reactive.addAttachmentButtonTap
    }

    var scrolledToTop: Signal<Void, NoError> {
        return base.collectionView.reactive.signal(forKeyPath: #keyPath(UIScrollView.contentOffset))
            .filterMap { $0 as? CGPoint }
            .filter { [weak base] point -> Bool in
                guard let base = base else { return false }
                let delta = base.collectionView.contentSize.height - point.y - base.collectionView.frame.height
                return delta < 100
            }
            .map { _ in () }
            .throttle(0.1, on: QueueScheduler.main)
    }

    var retryTap: Signal<Int, NoError> {
        return base.dataSource.reactive.retryTap
    }

    // Inputs
    var items: BindingTarget<[ChatViewItem]> {
        return BindingTarget(on: QueueScheduler.messages, lifetime: self.lifetime) { [weak base] items in
            base?.dataSource.load(items: items)
        }
    }

    var clearInputText: BindingTarget<Void> {
        return base.chatInputView.reactive.clearInputText
    }

    var showLastMessage: BindingTarget<Void> {
        return BindingTarget(on: QueueScheduler.main, lifetime: self.lifetime) { [weak base] () in
            guard let base = base else { return }
            let contentOffset = CGPoint(x: 0, y: -base.collectionView.contentInset.top)
            UIView.transition(with: base, duration: 0.4, options: UIViewAnimationOptions.transitionCrossDissolve, animations: {
                base.collectionView.contentOffset = contentOffset
            }, completion: nil)
        }
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
