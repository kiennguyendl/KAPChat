//
//  PhotoMessageCell.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/14/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit

protocol PhotoMessageCellDelegate: class{
    func tapOnMessageTypePhoto(cell: PhotoMessageCell, tap: UITapGestureRecognizer)
}

class PhotoMessageCell: MessageCell {
    
    @IBOutlet weak var messgePhotoImgView     : UIImageView!
    
    @IBOutlet weak var photoWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var photoHeightConstraint: NSLayoutConstraint!
    
    weak var delegatePhotoMessageCell: PhotoMessageCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapOnMessageTypePhoto(tap:)))
        self.messgePhotoImgView.addGestureRecognizer(tapGesture)
    }
    
    func tapOnMessageTypePhoto(tap: UITapGestureRecognizer) {
        delegatePhotoMessageCell?.tapOnMessageTypePhoto(cell: self, tap: tap)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
