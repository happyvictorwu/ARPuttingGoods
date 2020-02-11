//
//  GalleryTableViewCell.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/23.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import UIKit

class GalleryTableViewCell: UITableViewCell {
    @IBOutlet var modelImage: UIImageView!
    @IBOutlet var modelName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
