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

    @IBOutlet weak var followBottomButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!

    fileprivate let dataSource = ChatDataSource()
    fileprivate let isFollowingEnd = MutableProperty<Bool>(true)

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        collectionView.delegate = self
        dataSource.set(collectionView: collectionView)

        isFollowingEnd <~ collectionView.reactive.signal(forKeyPath: #keyPath(UIScrollView.contentOffset))
            .take(during: self.reactive.lifetime)
            .filterMap { $0 as? CGPoint }
            .map { [unowned self] point in
                return point.y + 40 > (self.collectionView.contentSize.height - self.collectionView.frame.height)
            }

        followBottomButton.reactive.isHidden <~ isFollowingEnd

        isFollowingEnd <~ followBottomButton.reactive.controlEvents(UIControlEvents.touchUpInside)
            .map { _ in true }

        isFollowingEnd.signal
            .take(during: self.reactive.lifetime)
            .combinePrevious()
            .filter { !$0.0 && $0.1 }
            .observeValues { [unowned self] _ in self.scrollToBottomIfNeeded() }
    }

    fileprivate func scrollToBottomIfNeeded() {
        if isFollowingEnd.value && dataSource.items.count > 0 {
            collectionView.scrollToItem(at: IndexPath(row: dataSource.items.count - 1, section: 0), at: UICollectionViewScrollPosition.centeredVertically, animated: true)
        }
    }
}

extension Reactive where Base: ChatView {
    func loadItems(_ items: Property<[ChatViewItem]>) {
        items.producer
            .take(during: base.reactive.lifetime)
            .startWithValues { [unowned base] items in
                base.dataSource.load(items: items)
                base.scrollToBottomIfNeeded()
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
        return UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
    }
}
