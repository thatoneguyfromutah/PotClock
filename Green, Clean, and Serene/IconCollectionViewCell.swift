//
//  IconCollectionViewCell.swift
//  PotClock
//
//  Created by Chase Angelo Giles on 11/6/23.
//

import UIKit

class IconCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    // MARK: - Selection
    
    override var isSelected: Bool {
        didSet {
            iconImageView.tintColor = isSelected ? .systemBackground : .systemGreen
            contentView.backgroundColor = isSelected ? .systemGreen : .systemGray5
        }
    }
}
