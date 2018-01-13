//
//  ChatsDataSource.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/12/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import Changeset

final class ChatsDataSource: NSObject {
    private weak var tableView: UITableView?
    private(set) var items = [ChatsViewItem]()

    func load(items: [ChatsViewItem]) {
        let changes = Changeset.edits(from: self.items, to: items)
        self.items = items
        tableView?.update(with: changes)
    }

    func set(tableView: UITableView) {
        tableView.register(ChatsLoadingCell.self, forCellReuseIdentifier: ChatsLoadingCell.reuseIdentifier)
        tableView.register(ChatsCell.self, forCellReuseIdentifier: ChatsCell.reuseIdentifier)
        tableView.register(ChatsInfoCell.self, forCellReuseIdentifier: ChatsInfoCell.reuseIdentifier)
        tableView.dataSource = self
        self.tableView = tableView
    }
}

extension ChatsDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row] {
        case .loading:
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatsLoadingCell.reuseIdentifier, for: indexPath) as! ChatsLoadingCell
            cell.startAnimating()
            return cell
        case let .chat(title, subtitle):
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatsCell.reuseIdentifier, for: indexPath) as! ChatsCell
            cell.configure(title: title, subtitle: subtitle)
            return cell
        case let .info(title, message):
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatsInfoCell.reuseIdentifier, for: indexPath) as! ChatsInfoCell
            cell.configure(title: title, message: message)
            return cell
        }
    }
}
