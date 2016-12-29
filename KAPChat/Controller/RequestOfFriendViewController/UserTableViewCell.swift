//
//  UserTableViewCell.swift
//  KAPChat
//
//  Created by Kien Nguyen Dang on 12/13/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
// protocol
protocol RequestDelegate: class{
    func tapOnButtonAccept(cell:UserTableViewCell)
    func tapOnButtonCancel(cell:UserTableViewCell)
}
class UserTableViewCell: UITableViewCell {

    weak var delegate: RequestDelegate?
    @IBOutlet weak var lblDisplatName: UILabel!
    @IBOutlet weak var imgAvt: UIImageView!
    
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnAccept: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func btnAccept(_ sender: Any) {
        delegate?.tapOnButtonAccept(cell: self)
    }
    
    @IBAction func btnCancel(_ sender: Any) {
        delegate?.tapOnButtonCancel(cell: self)
    }
    
}
