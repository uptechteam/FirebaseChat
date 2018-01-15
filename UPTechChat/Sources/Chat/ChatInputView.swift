//
//  ChatInputView.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/11/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import Result
import ReactiveSwift
import ReactiveCocoa

final class ChatInputView: UIView {
    fileprivate let addAttachmentButton = UIButton()
    fileprivate let textField = UITextField()
    fileprivate let sendButton = UIButton()
    fileprivate let (textFieldReturns, textFieldReturnsObserver) = Signal<Void, NoError>.pipe()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        let tintColor = UIColor(red: 12 / 255, green: 110 / 255, blue: 97 / 255, alpha: 1)

        addAttachmentButton.translatesAutoresizingMaskIntoConstraints = false
        addAttachmentButton.tintColor = tintColor
        addAttachmentButton.setTitleColor(tintColor, for: .normal)
        addAttachmentButton.setTitleColor(tintColor.withAlphaComponent(0.4), for: .focused)
        addAttachmentButton.setTitle("P", for: .normal)
        addAttachmentButton.titleLabel?.font = UIFont.systemFont(ofSize: 21)
        self.addSubview(addAttachmentButton)
        self.addConstraints([
            addAttachmentButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            addAttachmentButton.widthAnchor.constraint(equalToConstant: 40),
            addAttachmentButton.topAnchor.constraint(equalTo: self.topAnchor),
            addAttachmentButton.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 20
        containerView.layer.borderColor = UIColor(white: 0.94, alpha: 1).cgColor
        containerView.layer.borderWidth = 1
        self.addSubview(containerView)
        self.addConstraints([
            containerView.leadingAnchor.constraint(equalTo: addAttachmentButton.trailingAnchor),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            containerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(equalToConstant: 40)
        ])

        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Text Message"
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.tintColor = tintColor
        textField.returnKeyType = .send
        containerView.addSubview(textField)
        containerView.addConstraints([
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            textField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 2),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setTitle("S", for: .normal)
        sendButton.setTitleColor(UIColor.white, for: .normal)
        sendButton.setBackgroundImage(UIImage.cornerRoundedImage(color: tintColor, cornerRadius: 16), for: .normal)
        sendButton.setBackgroundImage(UIImage.cornerRoundedImage(color: tintColor.withAlphaComponent(0.7), cornerRadius: 16), for: .focused)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        containerView.addSubview(sendButton)
        containerView.addConstraints([
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor),
            sendButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4)
        ])
    }
}

extension ChatInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFieldReturnsObserver.send(value: ())
        return false
    }
}

extension Reactive where Base: ChatInputView {
    var inputTextChanges: Signal<String, NoError> {
        return base.textField.reactive.continuousTextValues
            .filterMap { $0 }
    }

    var sendButtonTap: Signal<Void, NoError> {
        let sendButtonTap = base.sendButton.reactive.controlEvents(.touchUpInside)
            .map { _ in () }

        return Signal.merge([sendButtonTap, base.textFieldReturns])
    }

    var addAttachmentButtonTap: Signal<Void, NoError> {
        return base.addAttachmentButton.reactive.controlEvents(.touchUpInside)
            .map { _ in () }
    }

    var clearInputText: BindingTarget<Void> {
        return BindingTarget(on: QueueScheduler.main, lifetime: self.lifetime) { [weak base] in
            base?.textField.text = ""
        }
    }
}
