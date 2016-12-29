//
//  TimeLineUserViewController.swift
//  KAPChat
//
//  Created by Kien Nguyen Dang on 12/13/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase
import AVKit
import AVFoundation

class TimeLineUserViewController: BaseAuthenticatedViewController ,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    @IBOutlet weak var btnAddFriend: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imgAvt: UIImageView!
    @IBOutlet weak var lblEmail: UILabel!
    
    var listPosts = [Post]()
    
    var userCurrent:User!
    
    var cache = NSCache<AnyObject,AnyObject>()
    
    var storage: FIRStorage!
    
    let newSize = CGSize(width: 100 , height: 200)
    let avtSize = CGSize(width: 40, height: 40)
    
    var uid: String!
    var email: String!
    var imagePicker = UIImagePickerController()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnAddFriend.layer.masksToBounds = true
        btnAddFriend.layer.cornerRadius = 10
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        //register cell for tableview
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "photoCell")
        tableView.register(UINib(nibName: "TextCell", bundle: nil), forCellReuseIdentifier: "textCell")
        tableView.register(UINib(nibName: "VideoCell", bundle: nil), forCellReuseIdentifier: "CellVideo")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 500
        
        // check friend
        //if is friend will be show the feeds of user
        checkFriend(uid: self.uid)
        
        //set size for avatar
        imgAvt.layer.cornerRadius = 0.5*imgAvt.layer.bounds.size.width
        imgAvt.layer.masksToBounds = true
        
        //add gesture for avatar if uid = current user id
        if uid == currentuserID{
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(TimeLineUserViewController.showDialog))
            imgAvt.addGestureRecognizer(tapGesture)
            imgAvt.isUserInteractionEnabled = true
        }
    }
    
    //show dialog for user change avatar
    func showDialog() {
        let alert = UIAlertController(title: "Ảnh đại diện", message: nil, preferredStyle: .actionSheet)
        //hiển thị tuỳ chọn cho người dùng nếu chưa đăng nhập hoặc chưa đăng ký
        alert.addAction(UIAlertAction(title: "Chọn ảnh từ gallary", style: .default, handler: { (action) in
            self.imagePicker.delegate = self
            self.imagePicker.allowsEditing = true
            self.imagePicker.sourceType = .photoLibrary
            
            self.present(self.imagePicker, animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Huỷ", style: .default, handler: { (action) in
            //
        }))
        alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = self.view.bounds
        self.present(alert, animated: true, completion: nil)
    }
    
    //pick and uploaf avatar into firebase
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imgAvt.contentMode = .scaleAspectFit
            imgAvt.image = pickedImage
            if let imgData = UIImageJPEGRepresentation(pickedImage, 0.1){
                let imgPath = NSUUID().uuidString
                uploadImageToFirebase(data: imgData as NSData, withPath: imgPath, completed: {(url) in
                    self.fireBaseRef.child("Users").child(self.currentuserID).child("avatarUrl").setValue(url)
                    self.userCurrent.avatarUrl = url
                    self.loadAvatar()
                    self.tableView.reloadData()
                })
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //upload image into firebase
    func uploadImageToFirebase(data:NSData, withPath: String, completed: @escaping(String) -> Void)
    {
        let storageRef = FIRStorage.storage().reference(withPath: "User/" + "\(withPath)")
        let uploadMetadata = FIRStorageMetadata()
        uploadMetadata.contentType = "image/jpeg"
        storageRef.put(data as Data, metadata: uploadMetadata) { (metadata,error) in
            if ( error != nil)
            {
                print("Error: Unable to upload image to Firebase storage")
            }else{
                print("Message: Successfully uploaded image to Firebase storage")
                print("Here's your download URL: \(metadata?.downloadURL())")
                let downloadURL = metadata?.downloadURL()?.absoluteString
                if let url = downloadURL {
                    completed(url)
                }
                
            }
        }
    }
    
    
    //send request to an user
    @IBAction func btnAddFriend(_ sender: Any) {
        let alert = UIAlertController(title: "", message: "Bạn có muốn thêm bạn bè?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Có", style: UIAlertActionStyle.default, handler: {(action) in
            self.sendRequestToUser(self.uid)
            self.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Không", style: UIAlertActionStyle.default, handler: {(action) in
            
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func sendRequestToUser(_ userID: String) {
        self.fireBaseRef.child("Users").child(userID).child("RequestFriend").child(self.currentuserID).setValue(true)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //check is friend or not
    //if not will be show button add friend and hide table view
    //else will be show table view and hide button add friend
    func checkFriend(uid: String){
        self.fireBaseRef.child("Users").child(uid).child("listFriend").observeSingleEvent(of: .value, with: {(snapshot: FIRDataSnapshot) in
            if let listFriend: [FIRDataSnapshot] = snapshot.children.allObjects as? [FIRDataSnapshot]{
                for friend in listFriend{
                    
                    if uid == friend.key || uid == self.currentuserID{
                        self.btnAddFriend.isEnabled = false
                        self.btnAddFriend.isHidden = true
                        self.tableView.isHidden = false
                        self.lblEmail.isHidden = true
                        //let list post of user
                        self.getListPostFromCurrentUser()
                        //get user info
                        self.getCurrentUserInfo()
                        self.tableView.reloadData()
                        return
                    }else{
                        self.lblEmail.isHidden = false
                        self.lblEmail.text = self.email
                        self.getCurrentUserInfo()
                        self.btnAddFriend.isEnabled = true
                        self.btnAddFriend.isHidden = false
                        self.tableView.isHidden = true
                    }
                    
                }
                

            }else{
                self.getCurrentUserInfo()
                self.btnAddFriend.isEnabled = true
                self.btnAddFriend.isHidden = false
                self.tableView.isHidden = true

            }
        })
        
    }
    
    //load avatar
    func loadAvatar() {
        //set size for img
        imgAvt.image = UIImage.imageWithColor(UIColor.lightGray, size: avtSize).createRadius(newSize: avtSize, radius: 22, byRoundingCorners: .allCorners)
        //get image from ram if cached
        if let avtDownloaded = cache.object(forKey: self.userCurrent.avatarUrl as AnyObject) as? UIImage {
            imgAvt.image = avtDownloaded
        } else {
            //if img not existed in ram. we will be download from firebase
            imgAvt.image = UIImage.imageWithColor(UIColor.lightGray, size: avtSize).createRadius(newSize: avtSize, radius: 22, byRoundingCorners: .allCorners)
            DispatchQueue.global().async {
                if let url = URL(string: self.userCurrent.avatarUrl) {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            if let img = UIImage(data: data) {
                                
                                let resultImg = img.scaleImage(newSize: self.avtSize).createRadius(newSize: self.avtSize, radius: 22, byRoundingCorners: .allCorners)
                                //Cache image to ram
                                self.cache.setObject(resultImg, forKey: self.userCurrent.avatarUrl as AnyObject)
                                self.imgAvt.image = resultImg
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func getCurrentUserInfo(){
        //let currentUserId = self.currentuserID
        self.fireBaseRef.child("Users").child(uid).observeSingleEvent(of: .value, with: {(snap) in
            
            guard let userDict = snap.value as? [String:AnyObject] else { return }
            
            if let user = User(uid: snap.key, JsonData: userDict) {
                self.userCurrent = user
                self.loadAvatar()
            }
            self.tableView.reloadData()
        })
    }
    
    //gget list post of user
    func getListPostFromCurrentUser(){
        
        self.fireBaseRef.child("Post").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            for item in snapshot.children.allObjects as! [FIRDataSnapshot]{
                if let postDictionary = item.value as? [String:AnyObject]{
                    let post = Post(postID: item.key, postData: postDictionary)
                    self.listPosts.append(post!)
                    self.sortPosts()
                }
            }
        })
    }
    
    //sort posts follow time post
    func sortPosts() {
        self.listPosts.sort{$0.time.compare($1.time as Date) == .orderedDescending}
        self.tableView.reloadData()
    }
    
}


extension TimeLineUserViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Lấy bài post ở vị trí row index
        let post = listPosts[indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH: mm - dd/MM/yyyy"
        
        let newSize = CGSize(width: 100 , height: 200)
        let avtSize = CGSize(width: 40, height: 40)
        
        // Nếu bài post có chứa hình
        
        
        
        if post.type == .Photo {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "photoCell") as? PostCell
            guard self.userCurrent != nil else {
                return cell!
            }
            cell?.post = post
            cell?.delegatePhotoPostCell = self
            cell?.usernameLbl.text = userCurrent?.displayName
            cell?.caption.text = post.caption
            cell?.likeLbl.text = String(post.likes)
            if post == listPosts.first{
                cell?.timeLbl.text = "🔴 " + formatter.string(from: post.time as Date)
            }else{
                cell?.timeLbl.text = "📅 " + formatter.string(from: post.time as Date)
            }
            if let imageDownloaded = cache.object(forKey: post.imageUrl as AnyObject) as? UIImage {
                cell?.postImg.image = imageDownloaded
            } else {
                let ref = FIRStorage.storage().reference(forURL: post.imageUrl!)
                ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                    if error != nil {
                        print("JESS: Unable to download image from Firebase storage")
                    } else {
                        print("JESS: Image downloaded from Firebase storage")
                        if let imgData = data {
                            if let img = UIImage(data: imgData) {
                                let resultImg = img.scaleImage(newSize: newSize)
                                self.cache.setObject(resultImg, forKey: post.imageUrl as AnyObject)
                                cell?.postImg.image = resultImg
                            }
                        }
                    }
                })
            }
            
            if let avtDownloaded = cache.object(forKey: self.userCurrent.avatarUrl as AnyObject) as? UIImage {
                cell?.profileImg.image = avtDownloaded
            } else {
                //Chứa cache thì lấy hình online và resize , Radius hình
                cell?.profileImg.image = UIImage.imageWithColor(UIColor.lightGray, size: avtSize).createRadius(newSize: avtSize, radius: 22, byRoundingCorners: .allCorners)
                DispatchQueue.global().async {
                    if let url = URL(string: self.userCurrent.avatarUrl) {
                        if let data = try? Data(contentsOf: url) {
                            DispatchQueue.main.async {
                                if let img = UIImage(data: data) {
                                    
                                    let resultImg = img.scaleImage(newSize: avtSize).createRadius(newSize: avtSize, radius: 22, byRoundingCorners: .allCorners)
                                    //Cache hình vào ram
                                    self.cache.setObject(resultImg, forKey: self.userCurrent.avatarUrl as AnyObject)
                                    cell?.profileImg.image = resultImg
                                }
                            }
                        }
                    }
                }
            }
            
            let likesRef = fireBaseRef.child("Post").child(uid).child((cell?.post.postId)!).child("listLike").child(currentuserID)
            likesRef.observe( .value, with: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    cell?.likeImg.image = UIImage(named: "empty-heart")
                } else {
                    cell?.likeImg.image = UIImage(named: "filled-heart")
                }
            })
            
            return cell!
        }
        else if post.type == .Video {
            self.startLoading()
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellVideo") as? VideoCell
            guard self.userCurrent != nil else {
                return cell!
            }
            cell?.post = post
            if let avtDownloaded = cache.object(forKey: self.userCurrent.avatarUrl as AnyObject) as? UIImage {
                cell?.profileImg.image = avtDownloaded
            } else {
                //Chứa cache thì lấy hình online và resize , Radius hình
                cell?.profileImg.image = UIImage.imageWithColor(UIColor.lightGray, size: avtSize).createRadius(newSize: avtSize, radius: 22, byRoundingCorners: .allCorners)
                DispatchQueue.global().async {
                    if let url = NSURL(string: self.userCurrent.avatarUrl) {
                        if let data = try? Data(contentsOf: url as URL) {
                            DispatchQueue.main.async {
                                if let img = UIImage(data: data) {
                                    
                                    let resultImg = img.scaleImage(newSize: avtSize).createRadius(newSize: avtSize, radius: 22, byRoundingCorners: .allCorners)
                                    //Cache hình vào ram
                                    self.cache.setObject(resultImg, forKey: self.userCurrent.avatarUrl as AnyObject)
                                    cell?.profileImg.image = resultImg
                                }
                            }
                        }
                    }
                }
            }
            cell?.usernameLbl.text = userCurrent?.displayName
            cell?.delegateVideoCell = self
            cell?.caption.text = post.caption
            cell?.likeLbl.text = String(post.likes)
            if post == listPosts.first{
                cell?.timeLbl.text = "🔴 " + formatter.string(from: post.time as Date)
            }else{
                cell?.timeLbl.text = "📅 " + formatter.string(from: post.time as Date)
            }
            
            if let imageDownloaded = cache.object(forKey: post.imageUrl as AnyObject) as? UIImage {
                cell?.videoImage.image = imageDownloaded
            } else {
                let ref = FIRStorage.storage().reference(forURL: post.imageUrl!)
                ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                    if error != nil {
                        print("JESS: Unable to download image from Firebase storage")
                    } else {
                        print("JESS: Image downloaded from Firebase storage")
                        if let imgData = data {
                            if let img = UIImage(data: imgData) {
                                let resultImg = img.scaleImage(newSize: newSize)
                                self.cache.setObject(resultImg, forKey: post.imageUrl as AnyObject)
                                cell?.videoImage.image = resultImg
                            }
                        }
                    }
                })
            }
            
            
            self.stopLoading()
            //var handle:UInt = 0
            let likesRef = fireBaseRef.child("Post").child(uid).child(post.postId!).child("listLike").child(currentuserID)
            likesRef.observe(.value, with: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    cell?.likeImg.image = UIImage(named: "empty-heart")
                } else {
                    cell?.likeImg.image = UIImage(named: "filled-heart")
                }
            })
            //likesRef.removeObserver(withHandle: handle)
            
            //Lấy avatar của user
            if let imageDownloaded = cache.object(forKey: self.userCurrent.avatarUrl as AnyObject) as? UIImage {
                cell?.profileImg.image = imageDownloaded
            }
            else {
                let userRef = FIRStorage.storage().reference(forURL: self.userCurrent.avatarUrl)
                userRef.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                    if error != nil {
                        print("JESS: Unable to download image from Firebase storage")
                    } else {
                        print("JESS: Image downloaded from Firebase storage")
                        if let imgData = data {
                            if let img = UIImage(data: imgData) {
                                let resultImg = img.scaleImage(newSize: avtSize)
                                self.cache.setObject(resultImg, forKey: self.userCurrent.avatarUrl as AnyObject)
                                cell?.profileImg.image = resultImg
                            }
                        }
                    }
                })
            }
            
            return cell!
        }else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "textCell") as? TextCell
            guard self.userCurrent != nil else {
                return cell!
            }
            cell?.post = post
            cell?.delegateTextPostCell = self
            cell?.usernameLbl.text = userCurrent?.displayName
            cell?.caption.text = post.caption
            cell?.likeLbl.text = String(post.likes)
            if post == listPosts.first{
                cell?.timeLbl.text = "🔴 " + formatter.string(from: post.time as Date)
            }else{
                cell?.timeLbl.text = "📅 " + formatter.string(from: post.time as Date)
            }
            
            // Ghi vết user đã like thì hiện filled - heart và ngược lại.
            //var handle:UInt = 0
            let likesRef = fireBaseRef.child("Post").child((cell?.post.createdBy)!).child((cell?.post.postId)!).child("listLike").child(currentuserID)
            likesRef.observe(.value, with: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    cell?.likeImg.image = UIImage(named: "empty-heart")
                } else {
                    cell?.likeImg.image = UIImage(named: "filled-heart")
                }
            })
            
            if let avtDownloaded = cache.object(forKey: self.userCurrent.avatarUrl as AnyObject) as? UIImage {
                cell?.profileImg.image = avtDownloaded
            } else {
                //Chứa cache thì lấy hình online và resize , Radius hình
                cell?.profileImg.image = UIImage.imageWithColor(UIColor.lightGray, size: avtSize).createRadius(newSize: avtSize, radius: 22, byRoundingCorners: .allCorners)
                DispatchQueue.global().async {
                    if let url = URL(string: self.userCurrent.avatarUrl) {
                        if let data = try? Data(contentsOf: url) {
                            DispatchQueue.main.async {
                                if let img = UIImage(data: data) {
                                    
                                    let resultImg = img.scaleImage(newSize: avtSize).createRadius(newSize: avtSize, radius: 22, byRoundingCorners: .allCorners)
                                    //Cache hình vào ram
                                    self.cache.setObject(resultImg, forKey: self.userCurrent.avatarUrl as AnyObject)
                                    cell?.profileImg.image = resultImg
                                }
                            }
                        }
                    }
                }
            }
            return cell!
        }
    }
}

//cell.customCell(post: post)
extension TimeLineUserViewController:PhotoPostCellDelegate, TextPostCellDelegate, VideoCellDelegate{
    func tapOnLinkUrlTextCell(cell: TextCell, tap: UITapGestureRecognizer) {
        if (cell.caption.text.isValidForUrl()){
            let url = cell.caption.text
            UIApplication.shared.openURL(URL(string: url!)!)
        }
    }
    
    
    func tapOnPhoto(cell: PostCell, tap: UITapGestureRecognizer) {
        let imageView = cell.postImg as UIImageView
        
        self.navigationController?.isNavigationBarHidden = true
        let newImageView = UIImageView(image: imageView.image)
        
        newImageView.frame = self.view.frame
        
        newImageView.backgroundColor = .black
        
        newImageView.contentMode = .scaleToFill
        
        newImageView.isUserInteractionEnabled = true
        
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissFullscreenImage(sender:)))
        
        newImageView.addGestureRecognizer(tap)
        
        self.view.addSubview(newImageView)
        
    }
    func dismissFullscreenImage(sender: UITapGestureRecognizer) {
        
        sender.view?.removeFromSuperview()
        
        self.navigationController?.isNavigationBarHidden = false
        
    }
    //tap on button like
    func tapOnLikeImage(cell: PostCell, tap: UITapGestureRecognizer) {
        let likesRef = fireBaseRef.child("Post").child(cell.post.createdBy!).child(cell.post.postId!).child("listLike").child(currentuserID)
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                cell.likeImg.image = UIImage(named: "filled-heart")
                cell.post.adjustLikes(addLike: true)
                likesRef.setValue(true)
                
            } else {
                cell.likeImg.image = UIImage(named: "empty-heart")
                cell.post.adjustLikes(addLike: false)
                likesRef.removeValue()
            }
            self.tableView.reloadData()
        })
    }
    
    //tap on button like
    func tapOnLikeImageTextCell(cell: TextCell, tap: UITapGestureRecognizer) {
        let likesRef = fireBaseRef.child("Post").child(cell.post.createdBy!).child(cell.post.postId!).child("listLike").child(currentuserID)
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                cell.likeImg.image = UIImage(named: "filled-heart")
                cell.post.adjustLikes(addLike: true)
                likesRef.setValue(true)
                
            } else {
                cell.likeImg.image = UIImage(named: "empty-heart")
                cell.post.adjustLikes(addLike: false)
                likesRef.removeValue()
            }
            self.tableView.reloadData()
        })
    }
    //MARK: Handle Tap On Like Image (post.type = video)
    func tapOnLikeImageVideoCell(cell: VideoCell, tap: UITapGestureRecognizer) {
        let likesRef = fireBaseRef.child("Post").child(cell.post.createdBy!).child(cell.post.postId!).child("listLike").child(currentuserID)
        likesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                cell.likeImg.image = UIImage(named: "filled-heart")
                cell.post.adjustLikes(addLike: true)
                likesRef.setValue(true)
                
            } else {
                cell.likeImg.image = UIImage(named: "empty-heart")
                cell.post.adjustLikes(addLike: false)
                likesRef.removeValue()
            }
            self.tableView.reloadData()
        })
        
    }
    
    //tap on a link
    func tapOnLinkUrl(cell: PostCell, tap: UITapGestureRecognizer) {
        
        if (cell.caption.text.isValidForUrl()){
            cell.textLabel?.textColor = UIColor.blue
            let url = cell.caption.text
            UIApplication.shared.openURL(URL(string: url!)!)
        }
        
    }
    
    //MARK: Handle Play Button (post.type = video)
    func tapOnPlayButton(cell: VideoCell, tap: UITapGestureRecognizer) {
        let stringURL = cell.post.videoUrl
        let videoURL = NSURL(string: stringURL!)
        let player = AVPlayer(url: videoURL! as URL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
    
    
    func tapOnLinkUrlVideoCell(cell: VideoCell, tap: UITapGestureRecognizer) {
        if (cell.post.caption?.isValidForUrl())!{
            cell.textLabel?.textColor = UIColor.blue
            let url = cell.caption.text
            UIApplication.shared.openURL(URL(string: url!)!)
        }
    }
    
    //MARK: - Get preview images of video
    func thumbnailForVideoAtURL(url: NSURL) -> UIImage? {
        
        let asset = AVAsset(url: url as URL)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        
        var time = asset.duration
        time.value = min(time.value, 5)
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("error")
            return nil
        }
    }
    
    func tapOnNameLablePostCell(cell: PostCell, tap: UITapGestureRecognizer) {
        
    }
    
    func tapOnNameLableTextCell(cell: TextCell, tap: UITapGestureRecognizer) {
        
    }
    
    func tapOnNameLableVideoCell(cell: VideoCell, tap: UITapGestureRecognizer) {
        
    }
    
}


