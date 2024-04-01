//
//  ExportLimitTableViewCell.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/16/23.
//

import UIKit

class ExportLimitTableViewCell: UITableViewCell {

    // MARK: - Properties
    
    @IBOutlet weak var limitImageView: UIImageView!
    @IBOutlet weak var limitNameLabel: UILabel!
    @IBOutlet weak var limitCategoryLabel: UILabel!
    
    // MARK: - Cell Lifecycle

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        limitImageView.tintColor = selected ? .systemGray6 : .systemGreen
        limitNameLabel.textColor = selected ? .systemGray6 : .label
        limitCategoryLabel.textColor = selected ? .systemGray6 : .label
        contentView.backgroundColor = selected ? .systemGreen : .systemGray6
    }
}
