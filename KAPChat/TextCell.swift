//
//  TextCell.swift
//  KAPChat
//
//  Created by PhatVQ on 17/12/2016.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
// Text post delegate
protocol TextPostCellDelegate: class{
    
    func tapOnLikeImageTextCell(cell:TextCell,tap:UITapGestureRecognizer)
    func tapOnNameLableTextCell(cell:TextCell,tap:UITapGestureRecognizer)
    func tapOnLinkUrlTextCell(cell: TextCell, tap: UITapGestureRecognizer)
}
class TextCell: UITableViewCell {
    weak var delegateTextPostCell:TextPostCellDelegate?
  
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var likeImg: UIImageView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var likeLbl: UILabel!
    
    var post: Post!   
    

    override func awakeFromNib() {
        // Add tap gesture on elenment
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnLikeImageTextCell(tap:)))
        likeImg.addGestureRecognizer(tap)
        likeImg.isUserInteractionEnabled = true
        
        let tapLink = UITapGestureRecognizer(target: self, action: #selector(tapOnLinkUrlTextCell(tap:)))
        tapLink.numberOfTapsRequired = 1
        caption.addGestureRecognizer(tapLink)
        caption.isUserInteractionEnabled = true
        
        let tapName = UITapGestureRecognizer(target: self, action: #selector(tapOnNameLableTextCell(tap:)))
        tapName.numberOfTapsRequired = 1
        usernameLbl.addGestureRecognizer(tapName)
        usernameLbl.isUserInteractionEnabled = true
        
        // Initialization code
        profileImg.layer.cornerRadius = 0.5*profileImg.layer.bounds.size.width
        profileImg.layer.masksToBounds = true
        
        let contentSize = caption.sizeThatFits(caption.bounds.size)
        var frame = caption.frame
        frame.size.height = contentSize.height
        caption.frame = frame
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func tapOnLinkUrlTextCell(tap: UITapGestureRecognizer){
        delegateTextPostCell?.tapOnLinkUrlTextCell(cell: self, tap: tap)
    }
    func tapOnLikeImageTextCell(tap: UITapGestureRecognizer){
        delegateTextPostCell?.tapOnLikeImageTextCell(cell: self, tap: tap)
    }
    
    func tapOnNameLableTextCell(tap: UITapGestureRecognizer) {
        delegateTextPostCell?.tapOnNameLableTextCell(cell: self, tap: tap)
    }
}
