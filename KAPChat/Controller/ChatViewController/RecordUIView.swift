//
//  RecordUIView.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/18/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit

class RecordUIView: UIView {
    var btnRecordPlay:UIButton!
    var btnRecordCancel:UIButton!
    var lblTime:UILabel!
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.btnRecordPlay = UIButton(type: UIButtonType.custom)
        self.btnRecordPlay.frame = CGRect(x: ((self.frame.size.width) / 2 ) - 40, y: ((self.frame.size.height) / 2 ) - 40, width: 80, height: 80)
        self.btnRecordPlay.setTitle("Ghi Âm", for: .normal)
        self.btnRecordPlay.backgroundColor = UIColor.red
        self.btnRecordPlay.layer.masksToBounds = true
        self.btnRecordPlay.layer.cornerRadius = 25
        self.btnRecordPlay.layer.borderWidth = 0.5
        self.btnRecordPlay.layer.borderColor = UIColor.black.cgColor
        
        
        
        
        self.btnRecordCancel = UIButton(type: .custom)
        self.btnRecordCancel.frame = CGRect(x: btnRecordPlay.frame.origin.x, y: btnRecordPlay.frame.origin.y + btnRecordPlay.frame.size.height + 5, width: 80, height: 30)
        self.btnRecordCancel.setTitle("Huỷ", for: .normal)
        self.btnRecordCancel.setTitleColor(UIColor.black, for: .normal)
        self.btnRecordCancel.layer.masksToBounds = true
        self.btnRecordCancel.layer.cornerRadius = 10
        self.btnRecordCancel.layer.borderWidth = 0.5
        self.btnRecordCancel.layer.borderColor = UIColor.black.cgColor
        
        self.lblTime = UILabel(frame: CGRect(x: self.btnRecordPlay.frame.origin.x, y: self.btnRecordPlay.frame.origin.y - 35, width: 80, height: 30))
        self.lblTime.text = "0s"
        self.lblTime.textColor = UIColor.red
        self.lblTime.textAlignment = .center
        self.lblTime.layer.masksToBounds = true
        self.lblTime.layer.cornerRadius = 10
        self.lblTime.layer.borderWidth = 0.5
        self.lblTime.layer.borderColor = UIColor.black.cgColor
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func displayBtnCancel(){
        self.addSubview(btnRecordCancel)
        self.addSubview(self.lblTime)
    }
    
    func hideBtnCancle(){
        self.btnRecordCancel.removeFromSuperview()
        self.lblTime.removeFromSuperview()
    }
    
    func updateTime(time:String){
        self.lblTime.text = time
    }
    
    func displayBtnRecordPlay(){
        self.addSubview(self.btnRecordPlay)
    }
    
    
    
    
}
