//
//  CreateChatTableViewCell.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/21/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit

class CreateChatTableViewCell: UITableViewCell {

    @IBOutlet weak var imgTick: UIImageView!
    @IBOutlet weak var imgAva: UIImageView!
    @IBOutlet weak var lblDisplayName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
