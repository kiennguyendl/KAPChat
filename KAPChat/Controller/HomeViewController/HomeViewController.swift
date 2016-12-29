//
//  HomeViewController.swift
//  KAPChat
//
//  Created by Kien Nguyen Dang on 12/9/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit

class HomeViewController: UITabBarController{
    var vc : ConversationsViewController!
    var vc2: ContactViewController!
    var vc3: FeedViewController!
    var vc4: UserinfoViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        let size = CGSize(width: 32.0, height: 32.0)
        
        let imgContact = UIImage(named: "contacticon")?.resizeImage(image: UIImage(named: "contacticon")!, targetSize: size)
        let imgConversation = UIImage(named: "message")?.resizeImage(image: UIImage(named: "message")!, targetSize: size)
        let imgFeed = UIImage(named: "feed")?.resizeImage(image: UIImage(named: "feed")!, targetSize: size)
        let imgProfile = UIImage(named: "profile")?.resizeImage(image: UIImage(named: "profile")!, targetSize: size)
        
        vc = ConversationsViewController()
        let tabbBarItem1 = UITabBarItem(title: "Conversation", image: imgConversation, tag: 0)
        vc.tabBarItem = tabbBarItem1
        
        
        vc2 = ContactViewController()
        let tabbBarItem2 = UITabBarItem(title: "Contact", image: imgContact, tag: 1)
        vc2.tabBarItem = tabbBarItem2
        
        vc3 = FeedViewController()
        let tabbBarItem3 = UITabBarItem(title: "News", image: imgFeed, tag: 2)
        vc3.tabBarItem = tabbBarItem3
        
        vc4 = UserinfoViewController()
        let tabbBarItem4 = UITabBarItem(title: "Profile", image: imgProfile, tag: 3)
        vc4.tabBarItem = tabbBarItem4
        self.viewControllers = [vc, vc2, vc3, vc4]
        
        
        
        
        //self.viewControllers?[0].navigationItem.rightBarButtonItem = rightBarButton
        
        self.navigationItem.title = "CONVERSATIONS"
        let rigthBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newConversation))
        self.navigationItem.rightBarButtonItem = rigthBarButtonItem
        
        if self.tabBarController?.tabBar.selectedItem?.tag == 1{
            let userButton = UIButton()
            userButton.setImage(UIImage(named: "friend"), for: .normal)
            userButton.frame = CGRect(origin: CGPoint(x: 10, y: 10), size: CGSize(width: 40, height: 40))
            userButton.addTarget(self, action: #selector(self.showScreenAddFriend), for: .touchUpInside)
            let rightBarButton = UIBarButtonItem()
            rightBarButton.customView = userButton
            self.navigationItem.rightBarButtonItem = rightBarButton
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        switch tabBar.selectedItem!.tag {
        case 0:
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.title = "CONVERSATIONS"
            let rigthBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newConversation))
            self.navigationItem.rightBarButtonItem = rigthBarButtonItem
            break
        case 1:
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem = nil
            let userButton = UIButton()
            userButton.setImage(UIImage(named: "friend"), for: .normal)
            userButton.frame = CGRect(origin: CGPoint(x: 10, y: 10), size: CGSize(width: 40, height: 40))
            userButton.addTarget(self, action: #selector(self.showScreenAddFriend), for: .touchUpInside)
            let rightBarButton = UIBarButtonItem()
            rightBarButton.customView = userButton
            self.navigationItem.rightBarButtonItem = rightBarButton
            self.navigationItem.title = "CONTACTS"
            break
        case 2:
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.title = "FEEDS"
            break
        case 3:
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.title = "PROFILE"
            break
        default: break
        }
    }
    func showScreenAddFriend() {
        let vc = AddFriendViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func newConversation(){
        let vc = CreateChatViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
}
extension HomeViewController:CreateChatProtocol{
    func pushConversationRoom(keyRoom: String) {
        let vc = ChatViewController()
        vc.conversationKey = keyRoom
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
