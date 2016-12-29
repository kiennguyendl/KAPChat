//
//  Conversations.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/14/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit


enum ConversationType {
    case Personal, Group
}
class Conversations: NSObject {
    var conversationkey:String
    var isLoading:Bool = false
    var type:ConversationType = .Personal
    init?(key:String, JsonData:[String:AnyObject]) {
        self.conversationkey = key
        guard let isLoadingData = JsonData["isLoading"] as? Bool, let typeData = JsonData["type"] as? String  else {
            return nil
        }
        self.isLoading = isLoadingData
        if typeData == "group" {
            self.type = .Group
        }else{
            self.type = .Personal
        }
    }
}
