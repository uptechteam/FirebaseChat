//
//  ChatView.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/8/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit

final class ChatView: UIView {
    @IBOutlet weak var collectionView: UICollectionView!

    private let dataSource = ChatDataSource()

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    private func setup() {
        dataSource.set(collectionView: collectionView)
    }
}
