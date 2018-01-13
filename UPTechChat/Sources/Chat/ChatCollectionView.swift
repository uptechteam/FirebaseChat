//
//  ChatCollectionView.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/13/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit

class ChatCollectionView: UICollectionView {
    let horizontalPanGestureRecognizer = UIPanGestureRecognizer()

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        horizontalPanGestureRecognizer.delegate = self
        self.addGestureRecognizer(horizontalPanGestureRecognizer)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard
            let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
            panGestureRecognizer === horizontalPanGestureRecognizer
        else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        let velocity = panGestureRecognizer.velocity(in: self)
        // Allow only horizontal pans
        return abs(velocity.x) > abs(velocity.y)
    }
}

extension ChatCollectionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
