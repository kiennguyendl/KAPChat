//
//  ChatViewController.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/7/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AssetsLibrary
import Photos
import AVFoundation

class ChatViewController: BaseAuthenticatedViewController {

    var conversationKey:String?
    

    @IBOutlet weak var btnSendFile: UIButton!
    @IBOutlet weak var btnSendMess: UIButton!
    @IBOutlet weak var NSConstraintsViewBottom: NSLayoutConstraint!
    
    @IBOutlet weak var NSConstraintsTxtInputHeight: NSLayoutConstraint!
    var messages:Array<Message> = []
    
    var isFirstLoad = true
    
    let concurrentQueuePhoto = DispatchQueue(label: "com.concurrent.anh", attributes: .concurrent)
    
    // Cache downloaded image
    var cacheImages = NSCache<AnyObject, AnyObject>()
    
    // Track các task download
    var downloadingTasks    = Dictionary<String,String>()
    var reloadCell = Dictionary<String,[IndexPath]>()
    
    // Dictionary lưu các url avatar users
    var userAvtDict         = Dictionary<String,String>()
    
    //Firebase Storage Image
    var imgSelected: String?
    var imgDataSelected:NSData?
    
    var imgPickerVC: UIImagePickerController?
    
    var flagCameraTakeOrSelectPhoto = 0
    
    // Limit query last messages
    let numberOfLastMessages: UInt = 25
    // Last item ID to paging
    var lastMessageKey:String?
    
    // Các biến kiểm soát load data
    var isLoadingData                   = false
    var hasNextData                     = true
    
    // Keyboard is presenting or not
    var keyboardPresenting              = false
    
    // Data source from Firebase
    var messagesRef:FIRDatabaseReference!
    
    // Avatar placeholder image
    let avtPlaceHolderImg:UIImage = UIImage.imageWithColor(UIColor.lightGray, size: CGSize(width: 30, height: 30)).createRadius(newSize: CGSize(width: 30, height: 30), radius: 15, byRoundingCorners: .allCorners)
    
    // Refesh controler for chat table
    let refeshControl = UIRefreshControl()
    
    var tapGesture:UITapGestureRecognizer!
    
    //Record
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var viewRecord:RecordUIView!
    var btnRecord:UIButton!
    var isHaveRecordView = false
    var timer:Timer!
    var audioFilename = ""
    var isCancelRecord = false
    
    @IBOutlet weak var tableMess: UITableView!
    @IBOutlet weak var txtInputChat: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesRef = self.fireBaseRef.child("Conversations/\(conversationKey!)/mesages")
        self.startLoading()
        setUpView()
        let rigthBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewUserIntoRoom))
        self.navigationItem.rightBarButtonItem = rigthBarButtonItem
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        // Do any additional setup after loading the view.
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addNewUserIntoRoom(){
        if self.audioRecorder != nil {
            self.recordCancel()
        }
        let vc = AddUserIntoConversationViewController()
        vc.conversationKey = self.conversationKey
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func keyBoardWillChangeFrame(notification: NSNotification){
        // check xem có viewrecord ko có thì ko change frame
        guard self.viewRecord == nil
        else {
            if self.audioRecorder != nil {
                self.recordCancel()
            }
            return
        }
        let keyBoardRect: CGRect = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        let keyBoardAnimationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! CGFloat
        self.NSConstraintsViewBottom.constant = (self.view.frame.size.height - keyBoardRect.origin.y)
        UIView.animate(withDuration: TimeInterval(keyBoardAnimationDuration), animations: {
            self.view.layoutIfNeeded()
        })
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.tableMess.addGestureRecognizer(tapGesture)
        
        
    }
    
    
    func hideKeyboard(){
        //Change frame và xoá record
        self.txtInputChat.resignFirstResponder()
        if self.viewRecord != nil {
            if self.audioRecorder != nil {
                self.recordCancel()
            }
            self.NSConstraintsViewBottom.constant = 0
            self.viewRecord.removeFromSuperview()
            UIView.animate(withDuration: 0.33, animations: { 
                self.view.layoutIfNeeded()
            })
            self.viewRecord = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //ẩn tabbar
        if let tabbar = self.tabBarController?.tabBar {
            let tabbarHeight = tabbar.bounds.size.height
            tableMess.contentInset.bottom = tabbarHeight + 40
            tableMess.scrollIndicatorInsets = tableMess.contentInset
        }
        
        //Check xem phải lần dầu load
        if isFirstLoad {
            isFirstLoad = false
            
            // 2.
            fetchConversationName()
            loadData(lastKey: nil)
            listenUserDidJoinConversationFromFirebase()
            listenMessageDidAddFromFirebase()
            listenMessageDidRemoveFromFirebase()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpView() {
        
        txtInputChat.layer.borderWidth = 1
        txtInputChat.layer.borderColor = UIColor(red: 206/255 ,green: 206/255, blue: 206/255 ,  alpha: 1 ).cgColor
        txtInputChat.layer.cornerRadius = 5
        
        tableMess.dataSource = self
        tableMess.delegate = self
        tableMess.register(UINib(nibName: "SenderTextTableViewCell", bundle: nil), forCellReuseIdentifier: "CellSender")
        tableMess.register(UINib(nibName: "SenderImageTableViewCell", bundle: nil), forCellReuseIdentifier: "CellSenderPhoto")
        tableMess.register(UINib(nibName: "SenderAudioTableViewCell", bundle: nil), forCellReuseIdentifier: "CellSenderAudio")
        tableMess.register(UINib(nibName: "ReceiveTextTableViewCell", bundle: nil), forCellReuseIdentifier: "CellReceiver")
        tableMess.register(UINib(nibName: "ReceiveImageTableViewCell", bundle: nil), forCellReuseIdentifier: "CellReceiverPhoto")
        tableMess.register(UINib(nibName: "ReceiveAudioTableViewCell", bundle: nil), forCellReuseIdentifier: "CellReceiverAudio")
        
        
        tableMess.estimatedRowHeight = 100
        tableMess.rowHeight = UITableViewAutomaticDimension
        txtInputChat.delegate = self
        self.tableMess.allowsSelection = false
        self.tableMess.addSubview(refeshControl)
    }
    
    
    // MARK: Data from Firebase
    // 2.
    func fetchConversationName() {
        
        // Đang load title cho phòng chat
        self.title = "..."
        //Lấy tên phòng chat
        self.fireBaseRef.child("Conversations/\(conversationKey!)/name").observeSingleEvent(of: .value, with: {[weak self] (snap) in
            guard let strongSelf = self else {return}
            // Trường hợp phòng chat riêng thì lấy theo uID logged in
            if let privateNameDict = snap.value as? [String:String] {
                
                if let privateName = privateNameDict[strongSelf.currentuserID] {
                    strongSelf.title = privateName
                }
                
            }
            
        })
    }
    
    /// Lắng nghe message mới từ Firebase
    func listenMessageDidAddFromFirebase() {
        messagesRef.queryLimited(toLast: 1).observe(.childAdded, with: {[weak self] (snap) in
            guard let strongSelf = self else {return}
            // Check message nếu đã tồn tại thì bỏ qua
            for msg in strongSelf.messages {
                if msg.messageId == snap.key {
                    return
                }
            }
            
            guard let messageInfo = snap.value as? [String:AnyObject] else { return }
            
            // Parse message và thêm vào mảng data chat
            if let message = Message(mesID: snap.key, messagesInfo: messageInfo) {
                strongSelf.messages.append(message)
                
                
                let indexPath = IndexPath(row: strongSelf.messages.count - 1, section: 0)
                strongSelf.tableMess.insertRows(at: [indexPath], with: .bottom)
                strongSelf.scrollTableViewToEnd()
            }
        })
    }
    
    /// Lắng nghe message bị xóa từ Firebase
    func listenMessageDidRemoveFromFirebase() {
        messagesRef.observe(.childRemoved, with: {[weak self] (snap) in
            guard let strongSelf = self else {return}
            if strongSelf.messages.count == 0 { return }
            
            let messageDeletedKey = snap.key
            
            // Tìm index của message cần xóa
            for i in 0 ..< strongSelf.messages.count {
                if let msg:Message = strongSelf.messages[i] {
                    if messageDeletedKey == msg.messageId {
                        
                        // Xóa message và update lại table view
                        strongSelf.messages.remove(at: i)
                        let indexPath = IndexPath(row: i, section: 0)
                        strongSelf.tableMess.deleteRows(at: [indexPath], with: .automatic)
                        
                        // Break để không phải tìm tiếp
                        break
                    }
                }
            }
        })
    }
    
    /// Lắng nghe khi có user join vào phòng chat từ Firebase
    /// Hàm này tận dụng lấy avatarURL của user lưu lại
    
    func listenUserDidJoinConversationFromFirebase() {
        self.fireBaseRef.child("Conversations").child(conversationKey!).child("name").observe(.childAdded, with: { (snap) in
            
            guard !snap.key.isEmpty else { return }
            let userID = snap.key
            self.fireBaseRef.child("Users").child(userID).observeSingleEvent(of: .value, with: {[weak self] (userSnap) in
                guard let strongSelf = self else {return}
                guard let userDict = userSnap.value as? [String:AnyObject] else { return }
                
                if let avatarURL = userDict["avatarUrl"] as? String {
                    strongSelf.userAvtDict[userSnap.key] = avatarURL
                    strongSelf.tableMess.reloadData()
                }
            })
            
        })
    }
    
    /// Load tin chat từ Firebase
    /// - parameter lastKey: Nếu = nil là load lần đầu, ngược lại là load phân trang
    // 3.
    func loadData(lastKey:String?) {
        
        // Nếu đang load data hoặc không có dữ liệu tiếp theo thì không làm gì cả
        if isLoadingData || !hasNextData { return }
        
        isLoadingData = true // bật trạng thái load data
        
        var dbRef:FIRDatabaseQuery!
        
        if let lastMessageKey = lastKey {
            dbRef = messagesRef.queryOrderedByKey().queryEnding(atValue: lastMessageKey).queryLimited(toLast: numberOfLastMessages + 1)
        } else {
            dbRef = messagesRef.queryOrderedByKey().queryLimited(toLast: numberOfLastMessages)
        }
        
        dbRef.observeSingleEvent(of: .value, with: {[weak self] (snap) in
            guard let strongSelf = self else {return}
            if let newItems = strongSelf.parseData(snapData: snap) {
                
                strongSelf.refeshControl.endRefreshing()
                
                strongSelf.hasNextData = UInt(newItems.count) == strongSelf.numberOfLastMessages
                
                // Nếu load lần đầu thì gán cả mảng data mới vào mảng data của table chat
                if strongSelf.lastMessageKey == nil {
                    strongSelf.messages = newItems
                    strongSelf.tableMess.reloadData()
                    strongSelf.scrollTableViewToEnd()
                }
                    // Khi có phân trang thì mảng data mới sẽ được thêm vào ngay trước mảng data của table chat
                else {
                    strongSelf.messages = newItems + strongSelf.messages
                    strongSelf.tableMess.reloadData()
                    
                }
                
                // Cập nhật message key cho lần phân trang tiếp theo
                strongSelf.lastMessageKey = strongSelf.getLastMessageKey()
            } else {
                
                strongSelf.hasNextData = false
            }
            
            // tắt trạng thái load data
            strongSelf.stopLoading()
            strongSelf.isLoadingData = false
        })
    }
    
    /// Lấy message key cũ nhất để làm cột mốc cho lần phân trang tiếp theo
    func getLastMessageKey() -> String? {
        
        guard let firstMessage = self.messages.first else { return nil }
        
        return firstMessage.messageId
    }
    
    /// Parse Data: Chuyển hóa JSON data từ Firebase -> model trong app
    func parseData(snapData: FIRDataSnapshot) -> Array<Message>? {
        
        if snapData.children.allObjects.count == 0 { return nil }
        
        var result = [Message]()
        
        for messageObj in snapData.children.allObjects {
            
            guard let messageSnap = messageObj as? FIRDataSnapshot else { continue }
            guard let messageInfo = messageSnap.value as? [String:AnyObject] else { continue }
            
            // Phân trang trong Firebase sẽ luôn có 1 item dư từ data cũ, vì ta phải query bắt đầu từ item này, nên mình cần bỏ qua nó lúc parse data
            if self.lastMessageKey == messageSnap.key { continue }
            
            if let message = Message(mesID: messageSnap.key, messagesInfo: messageInfo) {
                result.append(message)
            }
        }
        
        return result
    }
    
    func scrollTableViewToEnd() {
        let rowIndex = self.messages.count > 0 ? self.messages.count - 1 : 0
        let lastIndexPath = IndexPath(row: rowIndex, section: 0)
        
        self.tableMess.scrollToRow(at: lastIndexPath, at: .bottom , animated: false)
    }
    
    
    @IBAction func touchRecord(_ sender: Any) {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission({ (success) in
                //thành công thì tạo UI
                if success{
                    self.loadingUI()
                }
            })
        } catch {
            // failed to record!
        }
    }
    
    
    
    func startRecord() {
        isCancelRecord = false
        audioFilename = "\(Date())"
        let audioFileUrl = getDocumentsDirectory().appendingPathComponent("\(audioFilename).m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileUrl, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            self.viewRecord.displayBtnCancel()
            self.viewRecord.btnRecordPlay.setTitle("Dừng", for: .normal)
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.audioCheckTimeOut), userInfo: nil, repeats: true)
            
        } catch {
            finishRecording(success: false)
        }

    }
    

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func loadingUI(){
        //Chưa có view thì tạo view
        if self.viewRecord == nil {
            self.viewRecord = RecordUIView(frame: CGRect(x: 0, y: (self.view.frame.size.height) - 216, width: (self.view.frame.size.width), height: 216))
            self.viewRecord.btnRecordPlay.addTarget(self, action: #selector(self.recordTapped), for: .touchUpInside)
            self.viewRecord.btnRecordCancel.addTarget(self, action: #selector(self.recordCancel), for: .touchUpInside)
            self.NSConstraintsViewBottom.constant = self.viewRecord.frame.size.height
            self.view.addSubview(self.viewRecord)
            UIView.animate(withDuration: 0.33, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (success) in
                guard success == true else {return}
                self.viewRecord.displayBtnRecordPlay()
            })
            self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
            self.tableMess.addGestureRecognizer(self.tapGesture)
            self.txtInputChat.resignFirstResponder()
            isHaveRecordView = true
        }else{
            
            self.txtInputChat.resignFirstResponder()
        }


    }
    
    

    
    @IBAction func touchAttachment(_ sender: Any) {
        showChosePhoto()
        
    }
    
    //Photo thừ lib hoac chụp từ camera
    func showChosePhoto() {
        imgPickerVC = UIImagePickerController()
        imgPickerVC?.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            let openCamera = UIAlertAction(title: "Take a new photo", style: .default, handler: { (_) in
                self.imgPickerVC?.sourceType = .camera
                self.imgPickerVC?.isEditing = true
                self.present(self.imgPickerVC!, animated: true, completion: nil)
            })
            
            let openPhotoLibrary = UIAlertAction(title: "Choose from Library", style: .default, handler: { (_) in
                self.imgPickerVC?.sourceType = .photoLibrary
                self.imgPickerVC?.isEditing = true
                self.imgPickerVC?.allowsEditing = true
                self.present(self.imgPickerVC!, animated: true, completion: nil)
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            self.showAlertSheet(title: "", msg: "", actions: [cancel,openPhotoLibrary,openCamera])
            
        } else {
            imgPickerVC?.sourceType = .photoLibrary
            imgPickerVC?.isEditing = true
            imgPickerVC?.allowsEditing = true
            self.present(imgPickerVC!, animated: true, completion: nil)
        }
    }

    
    @IBAction func touchSend(_ sender: Any) {
        //Check xem có rổng không
        guard !txtInputChat.text.isEmpty else {return}
        let content = txtInputChat.text!
        //Gòi hàm gởi message len firebase
        self.sendMessageToFirebase(type: .Text, content: content, width: 0, height: 0, imgName: "")
        //Xoá text
        self.txtInputChat.text = ""
        //Set lại consatant mặc định là 30
        self.NSConstraintsTxtInputHeight.constant = 30
    }
    
    /// Send message to Firebase
    func sendMessageToFirebase(type: MessageType, content: String, width: Int, height: Int, imgName: String) {
        //Lấy giờ hiện tại
        let timeStamp       = NSDate().timeIntervalSince1970
        //Tao id message
        let newMsgRef = self.messagesRef.childByAutoId()
        var typeMess = "text"
        //Kiểm tra xem type message là gì
        if type == .Photo {
            typeMess = "photo"
        }else if type == .Audio{
            typeMess = "audio"
        }
        //Tạo thông tin message
        let messInfo = [
            "content" : content as AnyObject,
            "type": typeMess as AnyObject,
            "time" : timeStamp as AnyObject,
            "user_id" : self.currentuserID as AnyObject,
            "imgWidth": width as AnyObject,
            "imgHeight": height as AnyObject,
            "imgName": imgName as AnyObject
        ] as [String : AnyObject]
        
        newMsgRef.setValue(messInfo)
        
        // Update conversation firebase
        var lastMsg = content
        if type == .Photo {
            lastMsg = "Photo Messaged"
        }else if type == .Audio{
            lastMsg = "Audio Messaged"
        }
        self.fireBaseRef.child("Conversations/\(conversationKey!)/lastMessage").setValue(lastMsg)
        self.fireBaseRef.child("Conversations/\(conversationKey!)/lastTimeUpdated").setValue(timeStamp)
        
    }


}

extension ChatViewController:UITableViewDelegate,UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Lấy message ở row index
        let message = messages[indexPath.row]
        
        // Xác định cell id là của cell cho sender hay reciever
        var cellId = (message.sender == currentuserID) ? "CellSender" : "CellReceiver"
        
        // Nếu message là hình thì cell id thêm Photo
        if message.type == .Photo  {
            cellId += "Photo"
        }else if message.type == .Audio{
            cellId += "Audio"
        }
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! MessageCell
        cell.message = message
        cell.delegate = self
        
        // Thiết lập màu cho bong bóng chat
        if (message.sender == currentuserID) {
            cell.messageBubbleView.backgroundColor = UIColor(red: 204/255, green: 204/255, blue: 204/255 , alpha: 1)
        } else {
            cell.messageBubbleView.backgroundColor = UIColor(red: 242/255, green: 120/255, blue: 5/255 , alpha: 1)
        }
        
        // Hiển thị avatar
        cell.avtImageView.image = avtPlaceHolderImg
        
        // Lấy url user từ userAvtDict đã lưu sẵn
        if let avtURL = self.userAvtDict[message.sender] {
            
            // Nếu avt đã được download vào cache, lấy hình ra xài luôn
            if let avtDownloaded = cacheImages.object(forKey: avtURL as AnyObject) as? UIImage {
                cell.avtImageView.image = avtDownloaded
            } else {
                let newSize = CGSize(width: 30, height: 30)
                    DispatchQueue.global().async {
                        if let url = URL(string: avtURL) {
                            if let data = try? Data(contentsOf: url) {
                                DispatchQueue.main.async {[weak self] in
                                    if let img = UIImage(data: data) {
                                        guard let strongSelf = self else {return}
                                        let resultImg = img.scaleImage(newSize: newSize).createRadius(newSize: newSize, radius: 22, byRoundingCorners: .allCorners)
                                        //Cache hình vào ram
                                        strongSelf.cacheImages.setObject(resultImg, forKey: avtURL as AnyObject)
                                        //self.downloadingTasks.removeValue(forKey: message.sender)
                                        cell.avtImageView.image = resultImg
                                        //self.tableMess.reloadData()
                                    }
                                }
                            }
                        }
                    }
                
                
            }
        }
        
        // Nếu message là hình ảnh
        if message.type == .Photo {
            //cast về class PhotoMessageCell
            let photoChatCell = cell as! PhotoMessageCell
            
            photoChatCell.delegatePhotoMessageCell = self
            
            let urlImage = message.content
            
            // Scale size
            let newh = CGFloat(200 * message.imgHeight / message.imgWidth)
            
            photoChatCell.photoHeightConstraint.constant    = newh
            photoChatCell.photoWidthConstraint.constant     = 200
            
            // Check photo đã được download và đưa vào cache chưa,
            // nếu đã có thể lấy ra gán vào image view
            photoChatCell.messgePhotoImgView.image = nil
            
            if let downloadedPhoto = cacheImages.object(forKey: urlImage as AnyObject) as? UIImage {
                
                photoChatCell.messgePhotoImgView.image = downloadedPhoto
                
            } else {
                    //Kiểm tra hình đã được đưa vào queue down chưa
                    if downloadingTasks[message.messageId] == nil {
                        self.downloadingTasks[message.messageId] = urlImage
                        concurrentQueuePhoto.async {
                            if let url = URL(string: urlImage) {
                                if let data = try? Data(contentsOf: url) {
                                    DispatchQueue.main.async {[weak self] in
                                        guard let strongSelf = self else {return}
                                        if let img = UIImage(data: data) {
                                            
                                            let newSize = CGSize(width: 200, height: newh)
                                            let resultImg   = img.scaleImage(newSize: newSize)
                                            
                                            strongSelf.cacheImages.setObject(resultImg, forKey: urlImage as AnyObject)
                                            strongSelf.downloadingTasks.removeValue(forKey: message.messageId)
                                            photoChatCell.messgePhotoImgView.image = resultImg
                                            guard strongSelf.reloadCell[urlImage] != nil else {return}
                                            //update hình những cell cần
                                            for indexCell in strongSelf.reloadCell[urlImage]!{
                                                strongSelf.tableMess.reloadRows(at: [indexCell], with: .none)
                                            }
                                            strongSelf.reloadCell[urlImage] = nil
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }else{
                        //nếu hình đang được down thì gắn những cell cũng cần avartar Url đó vào mảng để reload lại
                        if self.reloadCell[urlImage] == nil {
                            self.reloadCell[urlImage] = [IndexPath]()
                        }
                        self.reloadCell[urlImage]?.append(indexPath)
                    }

                //}
            }
            
        }
            // Nếu message là text bình thường
        else if message.type == .Text{
            let textChatCell = cell as! TextMessageCell
            
            textChatCell.contentMessageLabel.text       = message.content
            textChatCell.contentMessageLabel.textColor  = UIColor.white
            
        }else if message.type == .Audio{//message là audio
            let audioChatCell = cell as! AudioMessageCell
            audioChatCell.delegateAudioMessageCell = self
            audioChatCell.lblTime.text = String(format: "%d",message.imgWidth)
        }

        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}

extension ChatViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // Chỉ làm việc với chat table, scrollview lúc này sẽ có khả năng là text view
        guard let chatTable = scrollView as? UITableView else { return }
        
        
        if chatTable.isDecelerating {
            
        }
    }
    
    /// Khi table view dừng scroll reload lại các visible cells để load các hình cần thiết
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        // Chỉ làm việc với chat table, scrollview lúc này sẽ có khả năng là text view
        //guard let chatTable = scrollView as? UITableView else { return }
        
        // Check nếu refeshControl đang chạy thì load data phân trang tiếp theo
        if refeshControl.isRefreshing {
            
            if hasNextData {
                loadData(lastKey: lastMessageKey)
            } else {
                refeshControl.endRefreshing()
            }
        }
        
    }
    
}

extension ChatViewController:UITextViewDelegate{
    func textViewDidChange(_ textView: UITextView) {
        
        self.btnSendMess.isEnabled = !textView.text.isEmpty
        
        // Chiều ngang cố định của text view, trừ 10 vì khoảng cách padding bên trong
        let fixedWidth = textView.bounds.size.width - 10
        
        // Lưu lại chiều cao lúc đầu của text view
        let fixedHeight:CGFloat = 30
        
        // Tính kích thước của text dựa trên font hiện tại của text view
        let msgContent = textView.text
        let newSize = NSString(string: msgContent!).boundingRect(
            with        : CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)),
            options     : [.usesLineFragmentOrigin, .usesFontLeading],
            attributes  : [NSFontAttributeName : textView.font!],
            context     : nil)
        
        // Chiều cao mới cho text view, thêm padding 4 để tạo thêm khoảng
        // cách cho trên và dưới
        let newTVHeight = max(newSize.size.height + 4, fixedHeight)
        
        guard newTVHeight < 100 else { return }
        // Cập nhật giá trị cho constraint chiều cao của text view
        NSConstraintsTxtInputHeight.constant = newTVHeight
        
        // Update layout cho view
        self.txtInputChat.superview?.layoutIfNeeded()
        

    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn  range: NSRange, replacementText text: String) -> Bool {
        //check có vượt quá ký tự (150)
        guard textView.text.characters.count < 150 || (range.length == 1 && text.characters.count == 0) else {
            return false
        }
        //nhấn nút return trên bàn phím thì gởi
        if (text == "\n") {
            textView.resignFirstResponder()
            if (textView.text.characters.count > 1) {
                performAction()
            }
        }
        return true
    }
    
    func performAction() {
        touchSend(sender: btnSendMess)
    }
}

extension ChatViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
            if let mediaType = info[UIImagePickerControllerMediaType] as? String {
                if mediaType == (kUTTypeImage as String) {
                    //check xem hình là chup hay lấy từ lib
                    if let imageUrl  = info[UIImagePickerControllerReferenceURL] as? NSURL {
                        if imageUrl.path != nil {
                            self.getImageFromPhotoLibrary(info: info as [String : AnyObject])
                        }
                    } else {
                        getImageFromTakePhoto(info: info as [String : AnyObject])
                    }
                }
            }
    }
    
    
    func getImageFromPhotoLibrary(info: [String:AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.uploadImgToFirebase(img: image)
        }
    }
    
    func getImageFromTakePhoto(info: [String:AnyObject]) {
        if let imgCap = info[UIImagePickerControllerOriginalImage] as? UIImage {
            PHPhotoLibrary.shared().performChanges({
            _ = PHAssetChangeRequest.creationRequestForAsset(from: imgCap)
            }, completionHandler: {[weak self] (success, error) in
                guard let strongSelf = self else {return}
                if success{
                    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                        
                        strongSelf.uploadImgToFirebase(img: image)
                        
                    }
                }
            })
            
        }
    }
    
    /// Handle image to upload to Firebase
    func uploadImgToFirebase(img: UIImage) {
        
        let imgW = Int(img.size.width)
        let imgH = Int(img.size.height)
        
        if let data = UIImageJPEGRepresentation(img, 0.07) {
            
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            let imgName = "\(NSDate()).jpg"
            self.storageLocal.child("Conversations").child("Image").child(conversationKey!).child(imgName).put(data, metadata: metadata, completion: {[weak self] (dataUpload, error) in
                guard let strongSelf = self else {return}
                if dataUpload != nil {
                    //thành công up hình lên firebase thì send message
                    if let content = dataUpload?.downloadURL()?.absoluteString {
                        strongSelf.sendMessageToFirebase(type: .Photo, content: content, width: imgW, height: imgH, imgName: imgName)
                    }
                }
            })
        }
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else {return}
            strongSelf.imgPickerVC?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func showAlertSavedImage() {
        
        let alert = UIAlertController(title: "Message", message: "Your photo was saved to Camera Roll", preferredStyle: .alert)
        
        let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(actionOK)
        
        self.present(alert, animated: true, completion: nil)
        
    }
}

extension ChatViewController:MessageCellDelegate,PhotoMessageCellDelegate,AudioMessageCellDelegate{
    func longPressOnMessage(cell: MessageCell, longPress: UILongPressGestureRecognizer) {
        //Lần đầu longPress sẽ là True, những lần sau sẽ là False, xét thấy là False thì thoát
        if  (longPress.state != .began) { return }
        //Lấy message trong từng cell ra
        guard let message = cell.message else { return }
        //Chỉ cho phép xoá tin nhắn của mình, không xóa được của người khác trong General
        if self.currentuserID == message.sender {
            let messageId = message.messageId
            let alertActionTakePhoto = UIAlertAction(title: "Delete it!", style: .destructive) {[weak self] (UIAlertAction) in
                //Xoá tin nhắn
                guard let strongSelf = self else {return}
                strongSelf.messagesRef.child(messageId).removeValue()
                if let imgName = message.imgName {
                    strongSelf.storageLocal.child("Conversations").child("Image").child(strongSelf.conversationKey!).child(imgName).delete(completion: { (error) in
                        if (error != nil) {
                            print("Failed to delete image file")
                        } else {
                            print("Oh yeah")
                        }
                    })
                }
            }
            let alertActionCancel = UIAlertAction(title: "Cancel", style: .default) { (UIAlertAction) in
            }
            self.showAlertSheet(title: "Delete message", msg: "Do you really want to delete this message?", actions: [alertActionTakePhoto, alertActionCancel])
        }
    }
    
    func tapOnMessageTypePhoto(cell: PhotoMessageCell, tap: UITapGestureRecognizer) {
        
        //print(cell.message.content)
        let photoVC =  PhotoViewController()
        photoVC.photoUrl = cell.message.content
        self.present(photoVC, animated: true, completion: nil)
        
    }
    
    func tapOnButtonTypeAudio(cell: AudioMessageCell, sender: UIButton) {
        // kiểm tra có đang playing
        if cell.isPlaying == false {
            cell.btnAudio.setImage(UIImage(named: "pause"), for: .normal)
            cell.isPlaying = true
            if let data = try? Data(contentsOf: URL(string: cell.message.content)!){
                cell.audioPlayer = try? AVAudioPlayer(data: data)
                guard cell.audioPlayer != nil else {return}
                cell.audioPlayer.prepareToPlay()
                cell.audioPlayer.play()
                cell.timerCell = Timer.scheduledTimer(timeInterval: 1, target: cell, selector: #selector(cell.updateTimeLbl), userInfo: nil, repeats: true)
                
            }
            

        }else{
            cell.timerCell.invalidate()
            cell.timerCell = nil
            cell.audioPlayer.stop()
            cell.btnAudio.setImage(UIImage(named: "play"), for: .normal)
            cell.lblTime.text = String(format: "%d",cell.message.imgWidth)
            cell.isPlaying = false
        }
    }
    
}

extension ChatViewController:AVAudioRecorderDelegate{
    //Kết thúc record
    func finishRecording(success: Bool) {
        print(audioRecorder.url)
        timer.invalidate()
        timer = nil


        
        
        if success && isCancelRecord == false{
            let time = Int((self.viewRecord.lblTime.text?.replacingOccurrences(of: "s", with: ""))!) ?? 0
            self.viewRecord.updateTime(time: "0s")
            let urlFile = audioRecorder.url
            self.viewRecord.btnRecordPlay.setTitle("Ghi âm", for: .normal)
            self.viewRecord.hideBtnCancle()
            if let data = try? Data(contentsOf: urlFile){
                let metadata = FIRStorageMetadata()
                metadata.contentType = "audio/mpeg"
                self.storageLocal.child("Conversations").child("Audio").child(conversationKey!).child(audioFilename).put(data, metadata: metadata, completion: {[weak self] (dataUpload, error) in
                    guard let strongSelf = self else {return}
                    if dataUpload != nil {
                        
                        if let content = dataUpload?.downloadURL()?.absoluteString {
                            strongSelf.sendMessageToFirebase(type: .Audio, content: content, width: time, height: 0, imgName: "")
                        }
                    }
                })

            }

        } else {
            if isCancelRecord == false {
                self.viewRecord.btnRecordPlay.setTitle("Ghi Âm", for: .normal)
                self.viewRecord.hideBtnCancle()
            }

            // recording failed :(
        }
        audioRecorder = nil
    }
    
    func recordTapped() {
        if audioRecorder == nil {
            startRecord()
            
        } else {
            audioRecorder.stop()
        }
    }
    
    func audioCheckTimeOut(){
        guard audioRecorder != nil else {return}
        if audioRecorder.currentTime >= 120 {
            audioRecorder.stop()
        }else{
            self.viewRecord.updateTime(time: String(format: "%.0f",audioRecorder.currentTime) + "s")
        }
    }
    
    //Huỷ record
    func recordCancel(){
        isCancelRecord = true
        audioRecorder.stop()
        audioRecorder.deleteRecording()
        self.viewRecord.btnRecordPlay.setTitle("Ghi âm", for: .normal)
        self.viewRecord.hideBtnCancle()
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        finishRecording(success: flag)
    }
    
}
extension ChatViewController:AddUserIntoConversationProtocol{
    //Load lại phòng chat
    func addUserIntoConversation(keyRoom: String) {
        self.conversationKey = keyRoom
        self.isFirstLoad = true
        self.isLoadingData = false
        self.hasNextData = true
        self.messagesRef.removeAllObservers()
        self.cacheImages.removeAllObjects()
        self.downloadingTasks.removeAll()
        self.messages.removeAll()
        NotificationCenter.default.removeObserver(self)
        self.viewDidLoad()
        self.viewDidAppear(true)
        self.tableMess.reloadData()

        self.stopLoading()
        
    }
}
