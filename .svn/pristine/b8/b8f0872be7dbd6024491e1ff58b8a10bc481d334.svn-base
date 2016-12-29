//
//  AudioMessageCell.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/18/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import AVFoundation

protocol AudioMessageCellDelegate: class{
    func tapOnButtonTypeAudio(cell: AudioMessageCell, sender: UIButton)
}

class AudioMessageCell: MessageCell {

    @IBOutlet weak var btnAudio: UIButton!
    @IBOutlet weak var lblTime: UILabel!
    
    var audioPlayer:AVAudioPlayer!
    var timerCell:Timer!
    var isPlaying = false
    weak var delegateAudioMessageCell: AudioMessageCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func touchBtnAudio(_ sender: UIButton) {
        delegateAudioMessageCell?.tapOnButtonTypeAudio(cell: self, sender: sender)
    }
    
    
    func updateTimeLbl() {
        guard audioPlayer != nil  else {return}
        
        
        if audioPlayer.currentTime > 0 {
            let time = audioPlayer.duration - audioPlayer.currentTime
            self.lblTime.text = String(format: "%.0f" , time)
        }else{
            self.delegateAudioMessageCell?.tapOnButtonTypeAudio(cell: self, sender: btnAudio)
        }
        
    }
    

}
