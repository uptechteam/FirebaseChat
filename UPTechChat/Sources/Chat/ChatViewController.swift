//
//  ChatViewController.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa

final class ChatViewController: UIViewController {
    private lazy var chatView: ChatView = {
        let nib = UINib(nibName: "ChatView", bundle: Bundle(for: ChatView.self))
        return nib.instantiate(withOwner: self, options: nil).first as! ChatView
    }()

    private let viewModel: ChatViewModel

    override func loadView() {
        self.view = chatView
    }

    convenience init(chatEntity: FirebaseEntity<Chat>) {
        self.init(viewModel: ChatViewModel(chatEntity: chatEntity))
    }

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(ChatViewController.shareBarButtonItemPressed(_:)))

        chatView.reactive.addAttachmentButtonTap
            .take(duringLifetimeOf: self)
            .observeValues { [weak self] in
                guard let `self` = self else { return }

                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self
                self.present(imagePickerController, animated: true, completion: nil)
            }

        bindViewModel()
    }

    private func bindViewModel() {
        chatView.reactive.items <~ viewModel.items

        viewModel.title.producer
            .take(duringLifetimeOf: self)
            .startWithValues { [weak self] in self?.title = $0 }

        chatView.reactive.clearInputText <~ viewModel.clearInputText

        viewModel.messageSendRetried
            .take(duringLifetimeOf: self)
            .observeValues { }

        chatView.reactive.showLastMessage <~ viewModel.showLastMessage
            .take(duringLifetimeOf: self)

        reactive.showAlert <~ viewModel.showAlert

        viewModel.showUrlShareMenu
            .take(duringLifetimeOf: self)
            .observeValues { [weak self] url in
                let viewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                viewController.excludedActivityTypes = [UIActivityType.addToReadingList]
                self?.present(viewController, animated: true, completion: nil)
            }

        chatView.reactive.inputTextChanges
            .observe(viewModel.inputTextChangesObserver)

        chatView.reactive.sendButtonTap
            .observe(viewModel.sendButtonTapObserver)

        chatView.reactive.scrolledToTop
            .observe(viewModel.scrolledToTopObserver)

        chatView.reactive.retryTap
            .observe(viewModel.retryTapObserver)
    }

    @objc private func shareBarButtonItemPressed(_ barButtonItem: UIBarButtonItem) {
        viewModel.shareMenuButtonTapObserver.send(value: ())
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage, let pngData = UIImagePNGRepresentation(image) {
            viewModel.pickedImageAttachmentObserver.send(value: (pngData, "png"))
        }

        self.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
