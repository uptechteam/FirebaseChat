//
//  ChatDataSource.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import Changeset

final class ChatDataSource: NSObject {
    private(set) var items = [ChatViewItem]()
    private weak var collectionView: ChatCollectionView?

    func set(collectionView: ChatCollectionView) {
        collectionView.register(ChatViewMessageCell.self, forCellWithReuseIdentifier: ChatViewMessageCell.reuseIdentifier)
        collectionView.register(ChatViewLoadingCell.self, forCellWithReuseIdentifier: ChatViewLoadingCell.reuseIdentifier)
        collectionView.register(ChatViewHeaderCell.self, forCellWithReuseIdentifier: ChatViewHeaderCell.reuseIdentifier)
        collectionView.dataSource = self
        self.collectionView = collectionView
    }

    func load(items: [ChatViewItem]) {
        let reversedItems = Array(items.reversed())
        let changes = Changeset.edits(from: self.items, to: reversedItems)
        self.items = reversedItems

        DispatchQueue.main.async {
            self.collectionView?.update(with: changes)
        }
    }
}

extension ChatDataSource: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        switch item {
        case .loading:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatViewLoadingCell.reuseIdentifier, for: indexPath) as! ChatViewLoadingCell
            cell.startAnimating()
            return cell
        case .header(let text):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatViewHeaderCell.reuseIdentifier, for: indexPath) as! ChatViewHeaderCell
            cell.configure(with: text)
            return cell
        case .message(let content):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatViewMessageCell.reuseIdentifier, for: indexPath) as! ChatViewMessageCell
            if let collectionView = collectionView as? ChatCollectionView {
                cell.configure(content: content, horizontalPanGestureState: collectionView.horizontalPanGestureRecognizer.reactive.stateChanged)
            }
            return cell
        }
    }
}
