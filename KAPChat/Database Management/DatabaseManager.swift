//
//  DatabaseManager.swift
//  KAPChat
//
//  Created by Kien Nguyen Dang on 12/7/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications



class DatabaseManager: NSObject {
    
    static var shareInstance = DatabaseManager()
    lazy var fireBaseRef:FIRDatabaseReference = FIRDatabase.database().reference()
    var userLogging:User!
    var arrUserFriend = [User]()
    var arrListChat = [RecentChat]()
    var countContact = 0
    var countConversations = 0
    var isFirstLoading = true
    
    func startApp(uid:String){
        self.getInfoUserLogging(uid: uid)
    }
    
    func checkFirstLoading(){
        //Hàm để check lấy hết dữ liệu về chưa
        if self.arrUserFriend.count == countContact && self.arrListChat.count == countConversations {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SuccessLoading"), object: nil)
            isFirstLoading = false
        }
    }
    
    func getInfoUserLogging(uid:String) {
        let currentUserId   = uid
        self.fireBaseRef.child("Users").child(currentUserId).observeSingleEvent(of: .value, with: {(snap) in
            
            guard let userDict = snap.value as? [String:AnyObject] else { return }
            
            if let user = User(uid: snap.key, JsonData: userDict) {
                self.userLogging = user
                self.countContact = self.userLogging.listFriend?.count ?? 0
                
                self.countConversations = self.userLogging.conversations.filter({$0.isLoading != false}).count
                if self.countContact == 0 && self.countConversations == 0 {
                    self.checkFirstLoading()
                }
                //tạo lắng nghe thay đổi của user logging
                self.fireBaseRef.child("Users").child(self.userLogging.id).observe(.childChanged, with: {(snap) in
                    if !(snap.value is NSNull) {
                        self.userLogging.setValue(snap.value, forKey: snap.key)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateUserLogging"), object: nil)
                        
                    }
                })
                //Lắng nghe Contact của userlogging
                self.userCurrentListFriendAdd()
                self.userCurrentListFriendDel()
                //Lắng nghe conversations cua userlogging
                self.listenConversationAddedFromFirebase()
                self.listUserConversationsChange()
                self.listenConversationRemovedFromFirebase()
                
            }
            
        })
    }
    
    //Lắng nghe Contact Firebase
    
    //Lắng nghe sự thay đổi của bạn bè
    func userChangeInfo(data:[User]) {
        if data.count > 0 {
            for item in data {
                self.fireBaseRef.child("Users").child(item.id).observe(.childChanged, with: {(snap) in
                    if !(snap.value is NSNull) {
                        for i in 0..<self.arrUserFriend.count {
                            if item.id == self.arrUserFriend[i].id {
                                self.arrUserFriend[i].setValue(snap.value, forKey: snap.key)
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserChangeInfo"), object: nil, userInfo: ["index" : i])
                                if snap.key == "avatarUrl"{
                                    //Bắn noti để update
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateAvatarUrl"), object: nil, userInfo: ["userId" : self.arrUserFriend[i].id , "avatarUrl" : self.arrUserFriend[i].avatarUrl])
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    //Lắng nghe khi có một contact mới được thêm vào
    func userCurrentListFriendAdd() {
        self.fireBaseRef.child("Users").child(self.userLogging.id).child("listFriend").observe(.childAdded, with: {(snap) in
            if !(snap.value is NSNull) && !(snap.key.isEmpty){
                self.fireBaseRef.child("Users").child(snap.key).observeSingleEvent(of: .value, with: {(snap) in
                    guard let userDict = snap.value as? [String:AnyObject] else { return }
                    if let userNew = User(uid: snap.key, JsonData: userDict) {
                        
                        //Thêm user mới vào mảng
                        
                        self.arrUserFriend.append(userNew)
                        let index = self.arrUserFriend.index(of: userNew)
                        //Noti thay đổi UI
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserFriendAdd"), object: nil, userInfo: ["index" : index!])
                        //Tạo lắng nghe thay đổi thông tin cho user mới
                        
                        self.userChangeInfo(data: [userNew])
                        
                        //Check FirstLoading
                        if self.isFirstLoading == true{
                            self.checkFirstLoading()
                        }
                        //pust local notification
                        
                        let content = UNMutableNotificationContent()
                        content.title = "KAPChat"
                        content.body = "bạn và " + userNew.displayName + " vừa trở thành bạn bè"
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd/MM/yyyy"
                        content.subtitle = dateFormatter.string(from: Date())
                        content.sound = UNNotificationSound.default()
                        content.userInfo = ["user" : userNew.id]
                        
                        
                        let trigger = UNTimeIntervalNotificationTrigger(
                            timeInterval: 0.1,
                            repeats: false)
                        
                        
                        let request = UNNotificationRequest(
                            identifier: "com.kapchat.contact",
                            content: content,
                            trigger: trigger)
                        
                        
                        //Add the notification to the currnet notification center
                        UNUserNotificationCenter.current().add(
                            request, withCompletionHandler: nil)
                    }
                    
                })
            }
        })
    }
    
    
    //Lắng nghe khi có một người bạn bị xoá
    func userCurrentListFriendDel() {
        self.fireBaseRef.child("Users").child(self.userLogging.id).child("listFriend").observe(.childRemoved, with: {(snap) in
            if !(snap.value is NSNull) && !(snap.key.isEmpty){
                for user in self.arrUserFriend{
                    if user.id == snap.key{
                        if let index = self.arrUserFriend.index(of: user){
                            self.arrUserFriend.remove(at: index)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserFriendDel"), object: nil, userInfo: ["index" : index])
                        }
                        
                    }
                }
            }
        })
    }
    
    //Lắng nghe Conversations
    
    func listUserConversationsChange(){
        self.fireBaseRef.child("Users").child(self.userLogging.id).child("conversations").observe(.childChanged, with: {(snap) in
            guard let snapDict = snap.value as? [String:AnyObject] else {return}
            for recentChat in self.arrListChat {
                if recentChat.keyID == snap.key { return }
            }
            guard let conversationUserAdd = Conversations(key: snap.key, JsonData: snapDict) else { return }
            
            //Lay id user trong phong chat
            
            self.fireBaseRef.child("Conversations").child(conversationUserAdd.conversationkey).observeSingleEvent(of: .value, with: {(snapData) in
                guard let snapCon = snapData.value as? [String:AnyObject] else { return }
                let newRecentChat = RecentChat()
                newRecentChat.keyID = snap.key
                newRecentChat.lastestMess = snapCon["lastMessage"]! as! String
                newRecentChat.lastUpdatedTime = snapCon["lastTimeUpdated"] as! Double
                newRecentChat.receiverUserID = snapCon["name"] as! [String:String]
                newRecentChat.type = conversationUserAdd.type
                if newRecentChat.type == .Personal{
                    let userReceiver = newRecentChat.receiverUserID.filter({$0.key != self.userLogging.id})[0]
                    newRecentChat.userDisplayName = newRecentChat.receiverUserID.filter({$0.key == self.userLogging.id})[0].value
                    self.fireBaseRef.child("Users").child(userReceiver.key).observeSingleEvent(of: .value, with: { (snapUser) in
                        guard let snapUserDict = snapUser.value as? [String:AnyObject] else {return}
                        newRecentChat.avatarURL = snapUserDict["avatarUrl"] as! String
                        
                        
                        //Bắn noti update UI
                        if conversationUserAdd.isLoading == true {
                            self.arrListChat.append(newRecentChat)
                            guard let index = self.arrListChat.index(of: newRecentChat) else {return}
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserConversationsChange"), object: nil, userInfo: ["index" : index])
                        }
                        self.listenConversationUpdatedFromFirebase(data: [newRecentChat])
                        
                    })
                }else{
                    newRecentChat.userDisplayName = newRecentChat.receiverUserID.filter({$0.key == self.userLogging.id})[0].value
                    newRecentChat.avatarURL = "https://firebasestorage.googleapis.com/v0/b/kapchat-ae080.appspot.com/o/User%2Fusergroup.png?alt=media&token=9566edae-1e44-48ab-9ef2-291fb2ced5a5"
                    
                    
                    //Bắn noti update UI
                    if conversationUserAdd.isLoading == true {
                        self.arrListChat.append(newRecentChat)
                        guard let index = self.arrListChat.index(of: newRecentChat) else {return}
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserConversationsChange"), object: nil, userInfo: ["index" : index])
                    }
                    self.listenConversationUpdatedFromFirebase(data: [newRecentChat])
                    
                }
                
                
                
            })
            
        })
    }
    
    // Lắng nghe node conversations của user đăng nhập khi có thêm mới
    func listenConversationAddedFromFirebase() {
        
        self.fireBaseRef.child("Users").child(self.userLogging.id).child("conversations").observe(.childAdded, with: { (snap) in
            
            
            guard let snapDict = snap.value as? [String:AnyObject] else { return }
            
            
            // Nếu phòng chat đã có trong mảng data thì bỏ qua
            for recentChat in self.arrListChat {
                if recentChat.keyID == snap.key { return }
            }
            guard let conversationUserAdd = Conversations(key: snap.key, JsonData: snapDict) else { return }
            
            //Lay id user trong phong chat
            
            self.fireBaseRef.child("Conversations").child(conversationUserAdd.conversationkey).observeSingleEvent(of: .value, with: {(snapData) in
                guard let snapCon = snapData.value as? [String:AnyObject] else { return }
                
                let newRecentChat = RecentChat()
                newRecentChat.keyID = snap.key
                newRecentChat.lastestMess = snapCon["lastMessage"]! as! String
                newRecentChat.lastUpdatedTime = snapCon["lastTimeUpdated"] as! Double
                newRecentChat.receiverUserID = snapCon["name"] as! [String:String]
                newRecentChat.type = conversationUserAdd.type
                if newRecentChat.type == .Personal{
                    //Lấy ra id người mình chát
                    let userReceiver = newRecentChat.receiverUserID.filter({$0.key != self.userLogging.id})[0]
                    //Display name của phòng
                    newRecentChat.userDisplayName = newRecentChat.receiverUserID.filter({$0.key == self.userLogging.id})[0].value
                    self.fireBaseRef.child("Users").child(userReceiver.key).observeSingleEvent(of: .value, with: { (snapUser) in
                        guard let snapUserDict = snapUser.value as? [String:AnyObject] else {return}
                        //Avatar phòng chát là của người chát trong phòng vs mình
                        
                        newRecentChat.avatarURL = snapUserDict["avatarUrl"] as! String
                        
                        
                        //Bắn noti update UI
                        if conversationUserAdd.isLoading == true{
                            self.arrListChat.append(newRecentChat)
                            guard let index = self.arrListChat.index(of: newRecentChat) else {return}
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ConversationAddedFromFirebase"), object: nil, userInfo: ["index" : index])
                        }

                        self.listenConversationUpdatedFromFirebase(data: [newRecentChat])
                        //Check FirstLoading
                        if self.isFirstLoading == true{
                            self.checkFirstLoading()
                        }
                    })
                }else{
                    newRecentChat.userDisplayName = newRecentChat.receiverUserID.filter({$0.key == self.userLogging.id})[0].value
                    newRecentChat.avatarURL = "https://firebasestorage.googleapis.com/v0/b/kapchat-ae080.appspot.com/o/User%2Fusergroup.png?alt=media&token=9566edae-1e44-48ab-9ef2-291fb2ced5a5"
                    
                    
                    //Bắn noti update UI
                    if conversationUserAdd.isLoading == true{
                        self.arrListChat.append(newRecentChat)
                        guard let index = self.arrListChat.index(of: newRecentChat) else {return}
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ConversationAddedFromFirebase"), object: nil, userInfo: ["index" : index])
                    }
                    self.listenConversationUpdatedFromFirebase(data: [newRecentChat])
                    //Check FirstLoading
                    if self.isFirstLoading == true{
                        self.checkFirstLoading()
                    }
                }

                
                
            })
            
        })
    }
    
    //Lắng nghe data của conversation thay đổi (node Conversations )
    func listenConversationUpdatedFromFirebase(data:[RecentChat]) {
        for recentChat in data {
            self.fireBaseRef.child("Conversations").child(recentChat.keyID).observe(.childChanged, with: { (snap) in
                guard snap.key == "lastMessage" || snap.key == "lastTimeUpdated" || snap.key == "mesages" || snap.key == "name"  else {return}
                //Khi thông tin của phòng chát thay đổi nghĩa là có người vừa chát update isLoading của phòng chat thành true của người đăng nhập
                self.fireBaseRef.child("Users").child(self.userLogging.id).child("conversations").child(recentChat.keyID).child("isLoading").setValue(true)
                
                
                for i in 0 ..< self.arrListChat.count {
                    let recentChatInArr = self.arrListChat[i]
                    if recentChatInArr.keyID == recentChat.keyID {
                        
                        //Cập nhật tin nhắn cuối
                        if snap.key == "lastMessage"{
                            guard let snapDict = snap.value as? String else { return }
                            recentChatInArr.lastestMess      = snapDict
                        }
                        // cập nhật time chát cuối
                        if snap.key == "lastTimeUpdated"{
                            guard let snapDict = snap.value as? String else { return }
                            recentChatInArr.lastUpdatedTime  = Double(snapDict)!
                        }
                        
                        if snap.key == "name"{
                            guard let snapDict = snap.value as? [String:String] else { return }
                            recentChatInArr.receiverUserID = snapDict
                        }
                        
                        if snap.key == "mesages"{
                            
                            guard let snapDict = snap.children.allObjects as? [FIRDataSnapshot] else { return }
                            guard let messageInfo = snapDict.last?.value as? [String:AnyObject] else { return }
                            // Parse message và thêm vào mảng data chat
                            if let message = Message(mesID: (snapDict.last?.key)!, messagesInfo: messageInfo) {
                                
                                if message.sender != self.userLogging.id{
                                    
                                    let content = UNMutableNotificationContent()
                                    let displayName = recentChat.receiverUserID.filter({$0.key == self.userLogging.id})[0].value
                                    content.title = displayName
                                    
                                    var body = message.content
                                    if message.type == MessageType.Photo{
                                        body = "Photo messaged"
                                    }else if message.type == MessageType.Audio{
                                        body = "Audio messaged"
                                    }
                                    content.body = body
                                    content.userInfo = ["roomKey" : recentChatInArr.keyID]
                                    content.sound = UNNotificationSound.default()
                                    let trigger = UNTimeIntervalNotificationTrigger(
                                        timeInterval: 0.1,
                                        repeats: false)
                                    
                                    
                                    let request = UNNotificationRequest(
                                        identifier: "com.kapchat.conversations",
                                        content: content,
                                        trigger: trigger)
                                    
                                    
                                    //Add the notification to the currnet notification center
                                    UNUserNotificationCenter.current().add(
                                        request, withCompletionHandler: nil)
                                }
                            }
                        }
                        
                        self.arrListChat[i] = recentChatInArr
                        //Bắn noti update UI
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ConversationUpdatedFromFirebase"), object: nil, userInfo: ["index" : i])
                        break
                    }
                }
            })
        }
        
    }
    
    // Lắng nghe node conversations của user đăng nhập khi có xoá
    func listenConversationRemovedFromFirebase() {
        
        self.fireBaseRef.child("Users").child(self.userLogging.id).child("conversations").observe(.childRemoved, with: { (snap) in
            
            for i in 0 ..< self.arrListChat.count {
                
                let recentChat = self.arrListChat[i]
                
                if snap.key == recentChat.keyID {
                    self.arrListChat.remove(at: i)
                    
                    //Bắn noti update UI
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ConversationRemovedFromFirebase"), object: nil, userInfo: ["index" : i])
                    break
                }
            }
        })
        
    }
    
}
