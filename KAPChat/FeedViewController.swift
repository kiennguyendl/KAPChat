//
//  FeedViewController.swift
//  KAPChat
//
//  Created by PhatVQ on 07/12/2016.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase
import AVKit
import AVFoundation
import MobileCoreServices

class FeedViewController: BaseAuthenticatedViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    var storage: FIRStorage!
    
    // Cache image
    var cache = NSCache<AnyObject,AnyObject>()
    
    //MARK: - Drag outlet from FeedViewController to swift file.
    @IBOutlet weak var captionField: UITextField!
    @IBOutlet weak var imageAdd: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postBtn: UIButton!
    
    //MARK: - Definition
    var startAnimation:Bool = true
    var userCurrent:User!
    var movieUrl:NSURL?
    var post:Post?
    var posts = [Post]()
    var users = [User]()
    
    var imagePicker = UIImagePickerController()
    var imageSelected = false
    var videoSelected = false
    
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        getListPostFromCurrentUserFriend()
        getUserInfo()
        
        // Disable the UITableview selection highlighting.
        tableView.allowsSelection = false
        
        tableView.dataSource = self
        tableView.delegate = self
        
        //Use “registerNib” on my tableView to add a custom cell
        tableView.register(UINib(nibName: "PostCell", bundle: nil), forCellReuseIdentifier: "CellPhoto")
        tableView.register(UINib(nibName: "TextCell", bundle: nil), forCellReuseIdentifier: "CellText")
        tableView.register(UINib(nibName: "VideoCell", bundle: nil), forCellReuseIdentifier: "CellVideo")
        
        // Custom tableview
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 500
        
        imageAdd.layer.cornerRadius = 0.5*imageAdd.layer.bounds.size.width
        imageAdd.layer.masksToBounds = true
        
        postBtn.layer.cornerRadius = 0.5*imageAdd.layer.bounds.size.width
        postBtn.layer.masksToBounds = true
        
        // Add tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(FeedViewController.addImageTapped(_:)))
        tap.numberOfTapsRequired = 1
        imageAdd.addGestureRecognizer(tap)
        imageAdd.isUserInteractionEnabled = true
        
        
        let tapPostBtn = UITapGestureRecognizer(target: self, action: #selector(FeedViewController.postBtnTapped(_:)))
        postBtn.addGestureRecognizer(tapPostBtn)
        postBtn.isUserInteractionEnabled = true
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func moveToTimeLineScreen(){
        let vc = TimeLineUserViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - Handle "Add Image Button"
    func addImageTapped(_ sender: UITapGestureRecognizer){
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.image","public.movie"]
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: - Handle "Post Button"
    @IBAction func postBtnTapped(_ sender: AnyObject) {
        self.startLoading()
        let caption = captionField.text
        // Check if users choose image
        if imageSelected == true{
            let img = imageAdd.image
            if let imgData = UIImageJPEGRepresentation(img!,0.1) {
                // Create A string containing a formatted UUID for example E621E1F8-C36C-495A-93FC-0C247A3E6E5F
                let imgUid = NSUUID().uuidString
                
                uploadImageToFirebase(data: imgData as NSData, withPath: imgUid, completed: { (url) in
                    self.postToFirebase(type:.Photo,caption: caption!, imgUrl: url, videoUrl: "")
                })
            }
        }
        // Check if user choose video
        else if videoSelected == true{
            uploadMovieToFirebase(url: movieUrl!, completed: { (videourl) in
                let videoImage = self.thumbnailForVideoAtURL(url: self.movieUrl!) // get preview image of the video
                if let imgData = UIImageJPEGRepresentation(videoImage!, 0.1){
                    // Create a preview image id containing a formatted UUID for example E621E1F8-C36C-495A-93FC-0C247A3E6E5F
                    let imgUid = NSUUID().uuidString
                    self.uploadImageToFirebase(data: imgData as NSData, withPath: imgUid, completed: { (imgurl) in
                        self.postToFirebase(type: .Video, caption: caption!, imgUrl: imgurl , videoUrl: videourl)
                    })
                }
            })
            
        }
        // Post have only text.
        else{
            self.postToFirebase(type: .Text, caption: caption!, imgUrl: "", videoUrl: "")
        }
        
        tableView.reloadData()
        showAlert(title: "Congratulation", message: "Your status has been updated onto news feed")
        self.stopLoading()
    }
    
    // MARK: - Upload Image to Firebase
    func uploadImageToFirebase(data:NSData, withPath: String, completed: @escaping(String) -> Void)
    {
        self.startLoading()
        let storageRef = FIRStorage.storage().reference(withPath: "Post/" + "\(withPath)")
        let uploadMetadata = FIRStorageMetadata()
        uploadMetadata.contentType = "image/jpeg" // Type of data
        
        //TODO: - Put image to Firebase storage.
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
        self.stopLoading()
    }
    
    // MARK: - Upload Movie to Firebase
    func uploadMovieToFirebase(url:NSURL, completed: @escaping(String) -> Void)
    {
        // Create A string containing a formatted UUID for example E621E1F8-C36C-495A-93FC-0C247A3E6E5F
        let videoUid = NSUUID().uuidString
        self.startLoading()
        let storageRef = FIRStorage.storage().reference(withPath: "Post/" + "\(videoUid)")
        let uploadMetadata = FIRStorageMetadata()
        uploadMetadata.contentType = "video/quicktime"
        
        //TODO: - Put video to firebase storage.
        storageRef.putFile(url as URL, metadata: uploadMetadata){ (metadata,error) in
            if (error != nil) {
                print("Got an error: \(error)")
            }else{
                print("Upload complete! Here's some metadata: \(metadata)")
                
                let downloadURL = metadata?.downloadURL()?.absoluteString
                if let url = downloadURL {
                    completed(url)
                }
            }
        }
        self.stopLoading()
        
    }
    
    
    //MARK: - Scroll to first row in tableview
    func scrollToFirstRow() {
        let indexPath = NSIndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: true)
    }
    //MARK: - Listen child added from post.
    func eventAddNewPost()
    {
        let currentUserId = self.currentuserID
        
        self.fireBaseRef.child("Post").child(currentUserId).observe(.childAdded, with:{(snapshot) in
            if let postDictionary = snapshot.value as? [String:AnyObject]{
                for item in self.posts{
                    if snapshot.key == item.postId{
                        return
                    }
                }
                let post = Post(postID: snapshot.key, postData: postDictionary)
                self.posts.append(post!)
                DispatchQueue.global().async{
                    DispatchQueue.main.async {
                        self.sortPosts()
                        self.scrollToFirstRow()
                    }
                }
                
            }
        })
        
        guard let userLoggingFriend = DatabaseManager.shareInstance.userLogging.listFriend?.keys else {return}
        for friend in userLoggingFriend {
            self.fireBaseRef.child("Post").child(friend).observe(.childAdded, with: { (listpost) in
                for item in self.posts{
                    if listpost.key == item.postId{
                        return
                    }
                }
                guard  let postDictionary = listpost.value as? [String:AnyObject] else {return}
                let post = Post(postID: listpost.key, postData: postDictionary)
                self.posts.append(post!)
                self.sortPosts()
                self.scrollToFirstRow()
                //self.tableView.reloadData()
                
                
            })
            
        }
    }
    //MARK: - Get All User Infomation
    func getUserInfo()
    {
        let currentUserId = self.currentuserID
        self.fireBaseRef.child("Users").child(currentUserId).observeSingleEvent(of: .value, with: {(snap) in
            
            guard let userDict = snap.value as? [String:AnyObject] else { return }
            
            if let user = User(uid: snap.key, JsonData: userDict) {
                self.userCurrent = user
                self.users.append(user)
            }
            
        })
        
        self.fireBaseRef.child("Users").child(currentUserId).child("listFriend").observeSingleEvent(of: .value, with: { (listfriend) in
            for friend in listfriend.children.allObjects  as! [FIRDataSnapshot]{
                
                self.fireBaseRef.child("Users").child(friend.key).observeSingleEvent(of: .value, with: {(snapshot) in
                    if let userDictionary = snapshot.value as? [String:AnyObject] {
                        if let user = User(uid: snapshot.key, JsonData: userDictionary) {
                            print("\(user.displayName)")
                            self.users.append(user)
                        }
                    }
                    
                })
            }
            
        })
    }
    
    
    //MARK: - Get list post of all user
    func getListPostFromCurrentUserFriend(){
        
        let currentUserId = self.currentuserID
        var handle:UInt = 0
        
        
        let refCurrentUser = self.fireBaseRef.child("Post").child(currentUserId)
        handle = refCurrentUser.observe(.value, with: { (snapshot) in
            guard let snapArr = snapshot.children.allObjects as? [FIRDataSnapshot] else {return}
            
            for item in snapArr {
                for item2 in self.posts{
                    if item.key == item2.postId{
                        return
                    }
                }
                if let postDictionary = item.value as? [String:AnyObject]{
                    let post = Post(postID: item.key, postData: postDictionary)
                    self.posts.append(post!)
                    self.sortPosts()
                }
            }
        })
        refCurrentUser.removeObserver(withHandle: handle)
        
        //Get list friend of current user
        guard let listuserFriendId = DatabaseManager.shareInstance.userLogging.listFriend?.keys else {return}
        //Get list post of current user
        for idFriend in listuserFriendId {
            self.fireBaseRef.child("Post").child(idFriend).observeSingleEvent(of: .value, with: { (listpost) in
                guard let listpostDict = listpost.children.allObjects as? [FIRDataSnapshot] else {return}
                for item in listpostDict {
                    if let postDictionary = item.value as? [String:AnyObject]{
                        for item2 in self.posts{
                            if item.key == item2.postId{
                                return
                            }
                        }
                        guard let post = Post(postID: item.key, postData: postDictionary) else {return}
                        self.posts.append(post)
                        self.sortPosts()
                    }
                }
            })
            eventAddNewPost()
            
        }
    }
    
    //MARK: - Sort an array of Post by date
    func sortPosts() {
        self.posts.sort{$0.time.compare($1.time as Date) == .orderedDescending}
        self.tableView.reloadData()
    }
    
    //MARK: - Post data to firebase
    func postToFirebase(type: PostType ,caption: String ,imgUrl: String, videoUrl: String ) {
        let currentUserId   = self.currentuserID
        let currentTime     = NSDate().timeIntervalSince1970
        
        var typePost = "text"
        
        if type == .Photo {
            typePost = "photo"
        }
        else if type == .Video{
            typePost = "video"
        }
        let post: [String : AnyObject] = [
            "caption": caption as AnyObject,
            "type": typePost as AnyObject,
            "imageUrl": imgUrl as AnyObject,
            "videoUrl": videoUrl as AnyObject,
            "time": currentTime as AnyObject,
            "likes": 0 as AnyObject,
            "listLike": true as AnyObject,
            "createdBy": currentUserId as AnyObject
        ]
        
        let firebasePost = self.fireBaseRef.child("Post").child(currentUserId).childByAutoId()
        firebasePost.setValue(post)
        
        captionField.text = ""
        imageSelected = false
        videoSelected = false
        imageAdd.image = UIImage(named: "add-image")
        
        tableView.reloadData()
    }
    
    //MARK: - Choosing Images with UIImagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let mediaType:String = info[UIImagePickerControllerMediaType] as? String else {
            dismiss(animated: true, completion: nil)
            return
        }
        //TODO: - Type is image
        if mediaType == (kUTTypeImage as String){
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                let pickedImageUrl = info[UIImagePickerControllerReferenceURL] as! NSURL
                imageAdd.contentMode = .scaleAspectFit
                imageAdd.image = pickedImage
                imageSelected = true
                print("\(pickedImageUrl)")
            }else{
                print("Error: A valid image wasn't selected")}
            dismiss(animated: true, completion: nil)
            
        }
            //TODO: - Type is video
        else if mediaType == (kUTTypeMovie as String){
            if let movieURL = info[UIImagePickerControllerMediaURL] as? NSURL{
                movieUrl = movieURL
                imageAdd.image = thumbnailForVideoAtURL(url: movieURL)
                videoSelected = true
                
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
}


extension FeedViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get post index.
        let post = posts[indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH: mm - dd/MM/yyyy"
        
        let newSize = CGSize(width: 100 , height: 200)
        let avtSize = CGSize(width: 40, height: 40)
        
        
        // If type = photo
        if post.type == .Photo {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellPhoto") as? PostCell
            cell?.post = post
            let arrUserCell = users.filter{($0.id == post.createdBy!)}
            if arrUserCell.count > 0 {
                let userCell = arrUserCell[0]
                cell?.usernameLbl.text = userCell.displayName
                
                //Get current user's avatar
                if let imageDownloaded = cache.object(forKey: userCell.avatarUrl as AnyObject) as? UIImage {
                    cell?.profileImg.image = imageDownloaded
                }
                else {
                    // download current user's avatar from firebase.
                    let userRef = FIRStorage.storage().reference(forURL: userCell.avatarUrl)
                    userRef.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                        if error != nil {
                            print("JESS: Unable to download image from Firebase storage")
                        } else {
                            print("JESS: Image downloaded from Firebase storage")
                            if let imgData = data {
                                if let img = UIImage(data: imgData) {
                                    let resultImg = img.scaleImage(newSize: avtSize) // scale image
                                    //cache image on RAM
                                    self.cache.setObject(resultImg, forKey: userCell.avatarUrl as AnyObject)
                                    cell?.profileImg.image = resultImg
                                }
                            }
                        }
                    })
                }
                
            }
            
            cell?.delegatePhotoPostCell = self
            
            cell?.caption.text = post.caption
            
            if (post.caption?.isValidForUrl())!{
                cell?.textLabel?.textColor = UIColor.blue
            }
            cell?.likeLbl.text = String(post.likes)
            
            if post == posts.first{
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
            
            //var handle:UInt = 0
            let likesRef = fireBaseRef.child("Post").child((cell?.post.createdBy)!).child((cell?.post.postId)!).child("listLike").child(currentuserID)
            likesRef.observe(.value, with: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    cell?.likeImg.image = UIImage(named: "empty-heart")
                } else {
                    cell?.likeImg.image = UIImage(named: "filled-heart")
                }
            })
            //likesRef.removeObserver(withHandle: handle)
            return cell!
        }
            // If type = video
        else if post.type == .Video {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellVideo") as? VideoCell
            cell?.post = post
            let arrUserCell = users.filter{($0.id == post.createdBy!)}
            if arrUserCell.count > 0 {
                let userCell = arrUserCell[0]
                cell?.usernameLbl.text = userCell.displayName
                
                //Lấy avatar của user
                if let imageDownloaded = cache.object(forKey: userCell.avatarUrl as AnyObject) as? UIImage {
                    cell?.profileImg.image = imageDownloaded
                }
                else {
                    let userRef = FIRStorage.storage().reference(forURL: userCell.avatarUrl)
                    userRef.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                        if error != nil {
                            print("JESS: Unable to download image from Firebase storage")
                        } else {
                            print("JESS: Image downloaded from Firebase storage")
                            if let imgData = data {
                                if let img = UIImage(data: imgData) {
                                    let resultImg = img.scaleImage(newSize: avtSize)
                                    self.cache.setObject(resultImg, forKey: userCell.avatarUrl as AnyObject)
                                    cell?.profileImg.image = resultImg
                                }
                            }
                        }
                    })
                }
                
            }
            
            cell?.delegateVideoCell = self
            cell?.caption.text = post.caption
            cell?.likeLbl.text = String(post.likes)
            if post == posts.first{
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
            
            let likesRef = fireBaseRef.child("Post").child((cell?.post.createdBy)!).child((cell?.post.postId)!).child("listLike").child(currentuserID)
            likesRef.observe(.value, with: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    cell?.likeImg.image = UIImage(named: "empty-heart")
                } else {
                    cell?.likeImg.image = UIImage(named: "filled-heart")
                }
            })
            return cell!
        }
            
            //TODO: - Text cell
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellText") as? TextCell
            cell?.post = post
            
            let arrUserCell = users.filter{($0.id == post.createdBy!)}
            if arrUserCell.count > 0 {
                let userCell = arrUserCell[0]
                cell?.usernameLbl.text = userCell.displayName
                
                //Lấy avatar của user
                if let imageDownloaded = cache.object(forKey: userCell.avatarUrl as AnyObject) as? UIImage {
                    cell?.profileImg.image = imageDownloaded
                }
                else {
                    let userRef = FIRStorage.storage().reference(forURL: userCell.avatarUrl)
                    userRef.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                        if error != nil {
                            print("JESS: Unable to download image from Firebase storage")
                        } else {
                            print("JESS: Image downloaded from Firebase storage")
                            if let imgData = data {
                                if let img = UIImage(data: imgData) {
                                    let resultImg = img.scaleImage(newSize: avtSize)
                                    self.cache.setObject(resultImg, forKey: userCell.avatarUrl as AnyObject)
                                    cell?.profileImg.image = resultImg
                                }
                            }
                        }
                    })
                }
                
            }
            
            cell?.delegateTextPostCell = self
            cell?.caption.text = post.caption
            cell?.likeLbl.text = String(post.likes)
            if post == posts.first{
                cell?.timeLbl.text = "🔴 " + formatter.string(from: post.time as Date)
            }else{
                cell?.timeLbl.text = "📅 " + formatter.string(from: post.time as Date)
            }

            let likesRef = fireBaseRef.child("Post").child((cell?.post.createdBy)!).child((cell?.post.postId)!).child("listLike").child(currentuserID)
            likesRef.observe(.value, with: { (snapshot) in
                if let _ = snapshot.value as? NSNull {
                    cell?.likeImg.image = UIImage(named: "empty-heart")
                } else {
                    cell?.likeImg.image = UIImage(named: "filled-heart")
                }
            })
            return cell!
            
        }
        
    }
}

extension FeedViewController:PhotoPostCellDelegate,TextPostCellDelegate,VideoCellDelegate{
    //MARK: View full size image
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
    
    //MARK: Handle Play Button (post.type = video)
    func tapOnPlayButton(cell: VideoCell, tap: UITapGestureRecognizer) {
        self.startLoading()
        let stringURL = cell.post.videoUrl
        let videoURL = NSURL(string: stringURL!)
        let player = AVPlayer(url: videoURL! as URL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        self.present(playerViewController, animated: true) {
            self.stopLoading()
            playerViewController.player!.play()
        }
    }
    //MARK: - Add tap gesture on link url of post -> safari
    func tapOnLinkUrl(cell: PostCell, tap: UITapGestureRecognizer) {
        if (cell.caption.text.isValidForUrl()){
            cell.textLabel?.textColor = UIColor.blue
            let url = cell.caption.text
            UIApplication.shared.openURL(URL(string: url!)!)
        }
    }

    func tapOnLinkUrlTextCell(cell: TextCell, tap: UITapGestureRecognizer) {
        if (cell.caption.text.isValidForUrl()){
            let url = cell.caption.text
            UIApplication.shared.openURL(URL(string: url!)!)
        }
    }

    func tapOnLinkUrlVideoCell(cell: VideoCell, tap: UITapGestureRecognizer) {
        if (cell.post.caption?.isValidForUrl())!{
            cell.textLabel?.textColor = UIColor.blue
            let url = cell.caption.text
            UIApplication.shared.openURL(URL(string: url!)!)
        }
    }
    //MARK: - Add tap gesture on user name lable
    func tapOnNameLablePostCell(cell: PostCell, tap: UITapGestureRecognizer) {
        let vc = TimeLineUserViewController()
        vc.uid = cell.post.createdBy
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tapOnNameLableTextCell(cell: TextCell, tap: UITapGestureRecognizer) {
        let vc = TimeLineUserViewController()
        vc.uid = cell.post.createdBy
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func tapOnNameLableVideoCell(cell: VideoCell, tap: UITapGestureRecognizer){
        let vc = TimeLineUserViewController()
        vc.uid = cell.post.createdBy
        self.navigationController?.pushViewController(vc, animated: true)
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
}

extension String{
    
    //MARK: - Check if text is a link
    func isValidForUrl()->Bool{
        
        if(self.hasPrefix("http://") || self.hasPrefix("https://") || self.hasPrefix("http://www.")){
            return true
        }
        return false
    }
}

