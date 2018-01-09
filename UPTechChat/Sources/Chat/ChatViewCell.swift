//
//  ChatViewCell.swift
//  UPTechChat
//
//  Created by Евгений Матвиенко on 1/9/18.
//  Copyright © 2018 uptechteam. All rights reserved.
//

import UIKit

class ChatViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.transform = CGAffineTransform(scaleX: -1, y: -1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
