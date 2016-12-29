//
//  RecentChat.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/8/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit

class RecentChat: NSObject {
    var keyID:String            = ""
    var avatarURL:String        = ""
    var userDisplayName:String  = ""
    var lastestMess:String      = ""
    var lastUpdatedTime:Double   = 0
    var receiverUserID   = [String:String]()
    var type:ConversationType = .Personal
}
