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
        collectionView.transform = CGAffineTransform(scaleX: -1, y: -1)
        collectionView.delegate = self
        dataSource.set(collectionView: collectionView)
    }
}

extension Reactive where Base: ChatView {
    func loadItems(_ items: Property<[ChatViewItem]>) {
        items.producer
            .take(during: base.reactive.lifetime)
            .map { Array($0.reversed()) }
            .startWithValues { [unowned base] items in
                base.dataSource.load(items: items)
            }
    }
}

extension ChatView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch dataSource.items[indexPath.row] {
        case .loading:
            return CGSize(width: collectionView.frame.width, height: 40)
        case .header:
            return CGSize(width: collectionView.frame.width, height: 16)
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
