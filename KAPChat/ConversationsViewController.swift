//
//  ConversationsViewController.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/8/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

class ConversationsViewController: BaseAuthenticatedViewController {
    
    var listChat = [RecentChat]()
    var listChatDontDisplay = [RecentChat]()
    // Cache downloaded image
    var cacheImages = NSCache<AnyObject, AnyObject>()
    //current user
    var userCurrent:User?
    //Check first load
    var isFirstLoad = true
    
    @IBOutlet weak var tableConversations: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableConversations.delegate = self
        tableConversations.dataSource = self
        tableConversations.rowHeight = UITableViewAutomaticDimension
        tableConversations.estimatedRowHeight = 100
        tableConversations.register(UINib(nibName: "ConversationsTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")

        // Do any additional setup after loading the view.
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Check có phải lần đầu load
        if isFirstLoad {
            isFirstLoad = false
            getData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getData(){
        //Tạo lắng nghe Notification và lấy dữ liệu từ lớp DataBaseManager
        self.startLoading()
        self.listChat = DatabaseManager.shareInstance.arrListChat
        self.userCurrent = DatabaseManager.shareInstance.userLogging
        self.tableConversations.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserLogging(noti:)), name: NSNotification.Name(rawValue: "UpdateUserLogging"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userConversationsChange(noti:)), name: NSNotification.Name(rawValue: "UserConversationsChange"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(conversationAddedFromFirebase(noti:)), name: NSNotification.Name(rawValue: "ConversationAddedFromFirebase"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(conversationUpdatedFromFirebase(noti:)), name: NSNotification.Name(rawValue: "ConversationUpdatedFromFirebase"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(conversationRemovedFromFirebase(noti:)), name: NSNotification.Name(rawValue: "ConversationRemovedFromFirebase"), object: nil)
        
        //Update avatar
        NotificationCenter.default.addObserver(self, selector: #selector(updateAvatarUrl(noti:)), name: NSNotification.Name(rawValue: "UpdateAvatarUrl"), object: nil)
        self.stopLoading()
        
        
    }
    
    //update thông tin user logging
    func updateUserLogging(noti: Notification){
        self.userCurrent = DatabaseManager.shareInstance.userLogging
    }
    
    //thêm phòng chat (personal thì có thể load hay không dựa vào biến isLoading , group thì luôn load)
    func userConversationsChange(noti: Notification){
        guard let index = noti.userInfo?["index"] as? Int else {return}
        self.listChat.append(DatabaseManager.shareInstance.arrListChat[index])
        self.tableConversations.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    //thêm phòng chat
    func conversationAddedFromFirebase(noti: Notification){
        guard let index = noti.userInfo?["index"] as? Int else {return}
        self.listChat.append(DatabaseManager.shareInstance.arrListChat[index])
        self.tableConversations.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    //cập nhật thông tin phòng chat
    func conversationUpdatedFromFirebase(noti: Notification){
        guard let index = noti.userInfo?["index"] as? Int else {return}
        if self.listChat.contains(DatabaseManager.shareInstance.arrListChat[index]) {
            self.listChat[index] = DatabaseManager.shareInstance.arrListChat[index]
            self.tableConversations.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }

    }
    
    //Lắng nghe xoá phòng chát
    func conversationRemovedFromFirebase(noti: Notification){
        guard let index = noti.userInfo?["index"] as? Int else {return}
        self.listChat.remove(at: index)
        self.tableConversations.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    //cập nhật avartar phòng chat
    func updateAvatarUrl(noti: Notification){
        guard let uid = noti.userInfo?["userId"] as? String else {return}
        let listChatTypePerson = self.listChat.filter({$0.type == .Personal})
        let recentChat = listChatTypePerson.filter({
            $0.receiverUserID.keys.contains(uid)
        })
        guard recentChat.count > 0 && recentChat.count == 1 else {
            return
        }
        guard let index = self.listChat.index(of: recentChat[0]) else {return}
        guard let avatar = noti.userInfo?["avatarUrl"] as? String else {return}
        self.listChat[index].avatarURL = avatar
        self.tableConversations.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        
        
    }
    
    //Xoa Notificationcenter
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    

    
    
    
    
}

extension ConversationsViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listChat.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? ConversationsTableViewCell
        if cell == nil {
            cell = ConversationsTableViewCell()
        }
        
        let recentChat = listChat[indexPath.row]
        cell?.lblNameConversations.text = recentChat.userDisplayName
        cell?.lblLastMessage.text = recentChat.lastestMess
        
        let newSize = CGSize(width: 44, height: 44)
        
        //Check hình có trên cache chưa có thì lấy ra xài
        if let avatDownloaded = cacheImages.object(forKey: recentChat.avatarURL as AnyObject) as? UIImage {
            cell?.imgConversations.image = avatDownloaded
        } else {
            
            cell?.imgConversations.image = UIImage.imageWithColor(UIColor.lightGray, size: newSize).createRadius(newSize: newSize, radius: 22, byRoundingCorners: .allCorners)
            //Chưa có thì down hình rồi update lại
            DispatchQueue.global().async {
                if let url = URL(string: recentChat.avatarURL) {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            if let img = UIImage(data: data) {
                                
                                let resultImg = img.scaleImage(newSize: newSize).createRadius(newSize: newSize, radius: 22, byRoundingCorners: .allCorners)
                                //cache hình vào ram
                                self.cacheImages.setObject(resultImg, forKey: recentChat.avatarURL as AnyObject)
                                cell?.imgConversations.image = resultImg
                            }
                        }
                    }
                }
            }
            
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recentChat = listChat[indexPath.row]
        if !recentChat.keyID.isEmpty {
            //push sang ChatViewController với id phòng chat
            let chatVC = ChatViewController()
            chatVC.conversationKey = recentChat.keyID
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let recentChat = listChat[indexPath.row]
            //Chat group thì xoá người đó khỏi phòng chat
            if recentChat.receiverUserID.keys.count > 2 {
                let alertAction = UIAlertAction(title: "ok", style: .destructive, handler: {[weak self] (action) in
                    guard let strongSelf = self else {return}
                    strongSelf.fireBaseRef.child("Users").child((strongSelf.userCurrent?.id)!).child("conversations").child(recentChat.keyID).removeValue()
                    strongSelf.fireBaseRef.child("Conversations").child(recentChat.keyID).child("name").child((strongSelf.userCurrent?.id)!).removeValue()
                })
                let cancelAction = UIAlertAction(title: "Cancel",
                                                 style: .default) { (action: UIAlertAction) -> Void in
                }
                self.showAlert(title: "Rời Khỏi Group Chat", msg: "Bạn có chắc chắn", actions: [alertAction,cancelAction])
             //chat personal thì ẩn phòng chát
            }else if recentChat.receiverUserID.keys.count == 2{
                self.fireBaseRef.child("Users").child((self.userCurrent?.id)!).child("conversations").child(recentChat.keyID).child("isLoading").setValue(false)
            }

            
            
            //listChat.remove(at: indexPath.row)
            //DatabaseManager.shareInstance.arrListChat.remove(at: indexPath.row)
            //tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        }
    }
    
    
}
