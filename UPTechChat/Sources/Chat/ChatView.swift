//
//  ChatView.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

final class ChatView: UIView {
    var collectionViewLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }

    @IBOutlet weak var collectionView: UICollectionView!

    fileprivate let dataSource = ChatDataSource()

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        collectionView.delegate = self
        dataSource.set(collectionView: collectionView)
    }
}

extension Reactive where Base: ChatView {
    func loadItems(_ items: Property<[ChatViewItem]>) {
        items.producer
            .take(during: base.reactive.lifetime)
            .startWithValues { [weak base] in base?.dataSource.load(items: $0) }
    }
}

extension ChatView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch dataSource.items[indexPath.row] {
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
}
