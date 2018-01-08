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
    private weak var collectionView: UICollectionView?

    func set(collectionView: UICollectionView) {
        collectionView.dataSource = self
        self.collectionView = collectionView
    }

    func load(items: [ChatViewItem]) {
        let changes = Changeset.edits(from: self.items, to: items)
        self.items = items
        collectionView?.update(with: changes)
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
        return UICollectionViewCell()
    }
}
