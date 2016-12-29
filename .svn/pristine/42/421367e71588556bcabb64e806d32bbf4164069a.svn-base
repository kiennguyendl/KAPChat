//
//  Post.swift
//  KAPChat
//
//  Created by PhatVQ on 08/12/2016.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase
enum PostType {
    case Text,Photo,Video
}
class Post:NSObject {
    
    var postId: String?
    var caption: String?
    var imageUrl: String?
    var videoUrl: String?
    var type:PostType = .Text
    var likes: Int = 0
    var listLike: Dictionary<String,Bool>?
    var createdBy: String?
    var time:NSDate = NSDate()
    private var _postRef: FIRDatabaseReference!
    
    
    init?(postID: String, postData: [String: AnyObject]) {
        self.postId = postID
        self.listLike = (postData["listLike"] as? [String:Bool])
        
        if let createdBy = postData["createdBy"] as? String {
            self.createdBy = createdBy
        }
        if let caption = postData["caption"] as? String {
            self.caption = caption
        }
        
        if let imageUrl = postData["imageUrl"] as? String{
            self.imageUrl = imageUrl
        }
        if let videoUrl = postData["videoUrl"] as? String{
            self.videoUrl = videoUrl
        }
        
        if let likes = postData["likes"] as? Int {
            self.likes = likes
        }
        
        if let timeInterval1970 = postData["time"] as? Double {
            if let date:NSDate = NSDate(timeIntervalSince1970: timeInterval1970) {
                self.time = date
            }
        }
        
        if let type = postData["type"] as? String {
            if type == "text" {
                self.type = .Text
            }
            else if type == "photo" {
                self.type = .Photo
            }
            else if type == "video"{
                self.type = .Video
            }
        }
        _postRef = DataService.ds.REF_POSTS.child(createdBy!).child(postId!)
    }
    func adjustLikes(addLike: Bool) {
        if addLike {
            likes = likes + 1
        } else {
            likes = likes - 1
        }
        _postRef.child("likes").setValue(likes)
    }
    
}
