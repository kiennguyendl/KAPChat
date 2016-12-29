//
//  CreateChatViewController.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/21/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase

protocol CreateChatProtocol: class{
    func pushConversationRoom(keyRoom:String)
}

class CreateChatViewController: BaseAuthenticatedViewController {

    weak var delegate:CreateChatProtocol?
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var tableContact: UITableView!
    var listContact = [User]()
    var userCurrent:User!
    var userSelected = [User]()
    var userSearch = [User]()
    var cache = NSCache<AnyObject,AnyObject>()
    var searchBar:UISearchBar!
    var viewHeader:UIView!
    var collectionView:UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startLoading()
        
        //table view
        tableContact.delegate = self
        tableContact.dataSource = self
        tableContact.register(UINib(nibName: "CreateChatTableViewCell", bundle: nil), forCellReuseIdentifier: "cell_contact")
        tableContact.rowHeight = UITableViewAutomaticDimension
        tableContact.estimatedRowHeight = 100
        self.viewHeader = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 40))
        self.searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 30))
        self.searchBar.delegate = self
        self.viewHeader.addSubview(searchBar)
        tableContact.tableHeaderView?.backgroundColor = UIColor.white
        tableContact.tableHeaderView = self.viewHeader
        
        //collection view
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.itemSize = CGSize(width: 50,height: 50)
        collectionViewLayout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60), collectionViewLayout: collectionViewLayout)
        collectionView.register(UINib(nibName: "UserCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        
        
        self.listContact = DatabaseManager.shareInstance.arrUserFriend
        self.userCurrent = DatabaseManager.shareInstance.userLogging
        self.userSearch = self.listContact
        self.tableContact.reloadData()
        self.stopLoading()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelTouch(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func doneTouch(_ sender: Any) {
        guard self.userSelected.count > 0 else {return}
        //phòng chát cá nhân, thì kiểm tra xem có tồn tại hay chưa
        if userSelected.count == 1  {
            guard let selectedUser:User = self.userSelected[0] else {return}
            
            self.pleaseWait()
            
            self.fireBaseRef.child("Users").child((userCurrent?.id)!).observeSingleEvent(of: .value, with: { (snap) in
                
                guard let userDict = snap.value as? [String:AnyObject] else { return }
                
                if let user = User(uid: snap.key, JsonData:userDict) {
                    
                    //Lấy ra phòng chát cá nhân của userLogging (Click vào 1 dòng của table contact chắc chắn là phòng chat personal)
                    let conversationUser = user.conversations.filter({$0.type == .Personal})
                    //Nều ko có phòng chat nào nghĩa là chưa tồn tại phòng chat -> create
                    guard conversationUser.count > 0
                        else {
                            self.createConversationWith(user: selectedUser)
                            return
                    }
                    var roomkey:String? = nil
                    var isHave = false
                    //Có phòng chat thì check xem có phòng chát với user chọn chưa
                    for i in 0..<conversationUser.count{
                        let conversation = conversationUser[i]
                        self.fireBaseRef.child("Conversations").child(conversation.conversationkey).child("name").child(selectedUser.id).observeSingleEvent(of: .value, with: {(snap) in
                            guard !(snap.value is NSNull)
                                else{
                                    //Check hết mà ko có thì tạo phòng
                                    if isHave == false && i == conversationUser.count - 1{
                                        self.createConversationWith(user: selectedUser)
                                    }
                                    return
                            }
                            roomkey = conversation.conversationkey
                            isHave = true
                            //Có thì push sang ChatViewController với id của phòng chat
                            self.dismiss(animated: true, completion: {
                                self.stopLoading()
                                self.delegate?.pushConversationRoom(keyRoom: roomkey!)
                            })
                            
                        })
                    }
                }
            })
        //Phòng chát nhóm thì tạo mới
        }else if self.userSelected.count > 1{
            
            self.pleaseWait()
            var userSelectedData = self.userSelected
            userSelectedData.append(userCurrent)
            self.createConversationGroupWith(user: userSelectedData)
        }
    }
    

    
    func createConversationWith(user: User) {
        
        
        guard let userCur = self.userCurrent else { return }
        //ID phòng chat
        let newRoomChatRef = self.fireBaseRef.child("Conversations").childByAutoId()
        //Thông tin phòng chat
        let conversationData = [
            "lastMessage"       : "",
            "lastTimeUpdated"   : NSDate().timeIntervalSince1970,
            "name"              : [
                userCur.id : user.displayName,
                user.id    : userCur.displayName
            ]
            ] as [String : Any]
        //Tạo phòng chat trên firebase
        newRoomChatRef.setValue(conversationData) { (err, ref) in
            if err == nil {
                //tạo dữ liệu trong listConversations của user
                let userConversationData = [
                    "isLoading": false,
                    "type": "personal"
                    ] as [String : Any]
                self.fireBaseRef.child("Users/\(user.id)/conversations/\(newRoomChatRef.key)").setValue(userConversationData)
                self.fireBaseRef.child("Users/\(userCur.id)/conversations/\(newRoomChatRef.key)").setValue(userConversationData)
                
                self.dismiss(animated: true, completion: {
                    self.delegate?.pushConversationRoom(keyRoom: newRoomChatRef.key)
                })
            }
        }
    }
    
    func createConversationGroupWith(user: [User]) {
        
        
        var nameRoom = ""
        let alert = UIAlertController(title: "New",
                                      message: "Add",
                                      preferredStyle: .alert)
        alert.title = "New Room"
        alert.message = "Add Name Room"
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: {[weak self] (action) in
            guard let strongself = self else {return}
            guard let name = (alert.textFields?[0])?.text else {return}
            guard !name.isEmpty
            else{
                self?.showAlert(title: "Thông báo", message: "Vui Lòng Nhập Tên Phòng.")
                return
            }
            nameRoom = name
            
            let newRoomChatRef = strongself.fireBaseRef.child("Conversations").childByAutoId()
            
            var nameDict = [String:String]()
            for i in 0..<user.count {
                nameDict[user[i].id] = nameRoom
            }
            //Thông tin phòng chat
            let conversationData = [
                "lastMessage"       : "",
                "lastTimeUpdated"   : NSDate().timeIntervalSince1970,
                "name"              : nameDict
                ] as [String : Any]
            //Tạo thông tin phòng chat trên firebase
            newRoomChatRef.setValue(conversationData) { (err, ref) in
                if err == nil {
                    //tạo dữ liệu trong listConversations của user
                    let userConversationData = [
                        "isLoading": true,
                        "type": "group"
                        ] as [String : Any]
                    for item in user{
                        strongself.fireBaseRef.child("Users/\(item.id)/conversations/\(newRoomChatRef.key)").setValue(userConversationData)
                    }
                    
                    strongself.dismiss(animated: true, completion: {
                        strongself.delegate?.pushConversationRoom(keyRoom: newRoomChatRef.key)
                    })
                }
            }
            
        })
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .default) { (action: UIAlertAction) -> Void in
        }
        alert.addTextField { (textField: UITextField) in
            textField.placeholder = "name"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
        self.stopLoading()

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
extension CreateChatViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userSearch.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell_contact") as? CreateChatTableViewCell
        if cell == nil {
            cell = CreateChatTableViewCell()
        }
        let userFriend = self.userSearch[indexPath.row]
        if self.userSelected.contains(userFriend) {
            cell?.imgTick.image = UIImage(named: "checked")
        }else{
            cell?.imgTick.image = nil
        }
        cell?.lblDisplayName.text = userFriend.displayName
        
        let newSize = CGSize(width: 50, height: 50)
        
        //Kiểm tra hình này đã cache chưa nối có thì lấy ra xài
        if let avtDownloaded = cache.object(forKey: userFriend.avatarUrl as AnyObject) as? UIImage {
            cell?.imgAva.image = avtDownloaded
        } else {
            //Chứa cache thì lấy hình online và resize , Radius hình
            cell?.imgAva.image = UIImage.imageWithColor(UIColor.lightGray, size: newSize).createRadius(newSize: newSize, radius: 22, byRoundingCorners: .allCorners)
            
            DispatchQueue.global().async {
                if let url = URL(string: userFriend.avatarUrl) {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            if let img = UIImage(data: data) {
                                
                                let resultImg = img.scaleImage(newSize: newSize).createRadius(newSize: newSize, radius: 22, byRoundingCorners: .allCorners)
                                //Cache hình vào ram
                                self.cache.setObject(resultImg, forKey: userFriend.avatarUrl as AnyObject)
                                cell?.imgAva.image = resultImg
                            }
                        }
                    }
                }
            }
        }
        
        
        
        return cell!
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = self.userSearch[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! CreateChatTableViewCell
        
        //Check xem user đã dc chọn chưa
        if self.userSelected.contains(user) {
            //nếu đã được chọn thì xoá chọn
            cell.imgTick.image = nil
            guard let index = self.userSelected.index(of: user) else {return}
            self.userSelected.remove(at: index)
            self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
            
            //Check xem còn user ko , ko thì xoá collection view
            if userSelected.count == 0 {

                UIView.animate(withDuration: 0.33, animations: {
                    self.collectionView.removeFromSuperview()
                    self.viewHeader.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 40)
                    self.searchBar.frame =  CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 30)
                    self.tableContact.tableHeaderView = self.viewHeader
                })
                
                
            }
        }else{
            //Nếu chưa dc chọn thì chọn
            cell.imgTick.image = UIImage(named: "checked")
            self.userSelected.append(user)
            guard let _ = self.userSelected.index(of: user) else {return}
            //Check xem có phải lần đầu ko , lần đầu thì add collection view
            if userSelected.count == 1 {

                UIView.animate(withDuration: 0.33, animations: {
                    self.viewHeader.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 100)
                    self.searchBar.frame =  CGRect(x: 0, y: 60, width: UIScreen.main.bounds.size.width, height: 30)
                    self.viewHeader.addSubview(self.collectionView)
                    self.tableContact.tableHeaderView = self.viewHeader
                })
            }
            collectionView.reloadData()
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension CreateChatViewController:UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            self.userSearch = self.listContact.filter({ $0.displayName.lowercased().contains(searchText.lowercased()) })
            self.tableContact.reloadData()
        }else{
            self.userSearch = self.listContact
            self.tableContact.reloadData()
        }
    }
}

extension CreateChatViewController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.userSelected.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? UserCollectionViewCell
        if cell == nil {
            cell = UserCollectionViewCell()
        }
        let user = self.userSelected[indexPath.row]
        let newSize = CGSize(width: 50, height: 50)
        
        //Kiểm tra hình này đã cache chưa nối có thì lấy ra xài
        if let avtDownloaded = cache.object(forKey: user.avatarUrl as AnyObject) as? UIImage {
            cell?.imgCollectUser.image = avtDownloaded
        } else {
            //Chứa cache thì lấy hình online và resize , Radius hình
            cell?.imgCollectUser.image = UIImage.imageWithColor(UIColor.lightGray, size: newSize).createRadius(newSize: newSize, radius: 22, byRoundingCorners: .allCorners)
            
            DispatchQueue.global().async {
                if let url = URL(string: user.avatarUrl) {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            if let img = UIImage(data: data) {
                                
                                let resultImg = img.scaleImage(newSize: newSize).createRadius(newSize: newSize, radius: 22, byRoundingCorners: .allCorners)
                                //Cache hình vào ram
                                self.cache.setObject(resultImg, forKey: user.avatarUrl as AnyObject)
                                cell?.imgCollectUser.image = resultImg
                            }
                        }
                    }
                }
            }
        }
        
        return cell!
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
}
