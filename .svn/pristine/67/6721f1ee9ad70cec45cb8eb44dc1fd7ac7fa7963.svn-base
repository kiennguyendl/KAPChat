//
//  MessageCell.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/14/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit

protocol MessageCellDelegate: class{
    func longPressOnMessage(cell: MessageCell, longPress: UILongPressGestureRecognizer)
}

class MessageCell: UITableViewCell {
    weak var delegate: MessageCellDelegate?
    
    @IBOutlet weak var avtImageView     : UIImageView!
    @IBOutlet weak var messageBubbleView: UIView!
    
    var message:Message!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let longTapGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnMessage(longPress:) ))
        self.messageBubbleView.addGestureRecognizer(longTapGesture)
        self.messageBubbleView.layer.cornerRadius = 10
        self.messageBubbleView.layer.masksToBounds = true
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func longPressOnMessage(longPress: UILongPressGestureRecognizer) {
        delegate?.longPressOnMessage(cell: self, longPress: longPress)
    }
    

}
