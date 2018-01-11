//
//  ViewController.swift
//  UPTechChat
//
//  Created by Evgeny Matviyenko on 1/4/18.
//  Copyright © 2018 upteachteam. All rights reserved.
//

import UIKit
import FirebaseDatabase
import RxSwift

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private var chatEntities = [FirebaseEntity<Chat>]()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Chats"
        tableView.dataSource = self
        tableView.delegate = self

        setupBindings()
    }

    private func setupBindings() {
        let database = Database.database().reference()
        let provider = Provider<Chat>(reference: database.child("chats"))

        provider.fetch()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chatEntities in
                self?.chatEntities = chatEntities
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatEntities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)

        let chat = chatEntities[indexPath.row]
        cell.textLabel?.text = chat.model.name
        cell.detailTextLabel?.text = chat.model.lastMessage?.body

        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let chatEntity = chatEntities[indexPath.row]
        let chatViewController = ChatViewController(viewModel: ChatViewModel(messagesProvider: .init(database: Database.database()), userProvider: .init(), chatEntity: chatEntity))
        navigationController?.pushViewController(chatViewController, animated: true)
    }
}
