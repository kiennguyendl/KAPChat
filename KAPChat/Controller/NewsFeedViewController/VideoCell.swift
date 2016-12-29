//
//  VideoCell.swift
//  KAPChat
//
//  Created by PhatVQ on 21/12/2016.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
// Video Cell delegate
protocol VideoCellDelegate: class{
    func tapOnLikeImageVideoCell(cell:VideoCell,tap:UITapGestureRecognizer)
    func tapOnPlayButton(cell:VideoCell,tap:UITapGestureRecognizer)
    func tapOnLinkUrlVideoCell(cell:VideoCell,tap:UITapGestureRecognizer)
    func tapOnNameLableVideoCell(cell: VideoCell,tap:UITapGestureRecognizer)
}
class VideoCell: UITableViewCell {
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var likeImg: UIImageView!
    @IBOutlet weak var likeLbl: UILabel!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var videoImage: UIImageView!
    @IBOutlet weak var playVideo: UIButton!
    
    weak var delegateVideoCell:VideoCellDelegate?
    
    var post: Post!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Add tap gesture on element in post
        let tapLike = UITapGestureRecognizer(target: self, action: #selector(tapOnLikeImageVideoCell(tap:)))
        tapLike.numberOfTapsRequired = 1
        likeImg.addGestureRecognizer(tapLike)
        likeImg.isUserInteractionEnabled = true
        
        let tapLink = UITapGestureRecognizer(target: self, action: #selector(tapOnLinkUrlVideoCell(tap:)))
        tapLink.numberOfTapsRequired = 1
        caption.addGestureRecognizer(tapLink)
        caption.isUserInteractionEnabled = true
        
        let tapPlayButton = UITapGestureRecognizer(target: self, action: #selector(tapOnPlayButton(tap:)))
        tapLike.numberOfTapsRequired = 1
        playVideo.addGestureRecognizer(tapPlayButton)
        playVideo.isUserInteractionEnabled = true
        
        let tapName = UITapGestureRecognizer(target: self, action: #selector(tapOnNameLableVideoCell(tap:)))
        tapName.numberOfTapsRequired = 1
        usernameLbl.addGestureRecognizer(tapName)
        usernameLbl.isUserInteractionEnabled = true
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func tapOnLikeImageVideoCell(tap: UITapGestureRecognizer){
        delegateVideoCell?.tapOnLikeImageVideoCell(cell: self, tap: tap)
    }
    func tapOnPlayButton(tap: UITapGestureRecognizer){
        delegateVideoCell?.tapOnPlayButton(cell: self, tap: tap)
    }
    func tapOnLinkUrlVideoCell(tap: UITapGestureRecognizer){
        delegateVideoCell?.tapOnLinkUrlVideoCell(cell: self, tap: tap)
    }
    func tapOnNameLableVideoCell(tap: UITapGestureRecognizer) {
        delegateVideoCell?.tapOnNameLableVideoCell(cell: self, tap: tap)
    }
}






