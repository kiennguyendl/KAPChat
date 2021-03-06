//
//  BaseViewController.swift
//  KAPChat
//
//  Created by Kien Nguyen Dang on 12/8/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase
import SystemConfiguration

class BaseViewController: UIViewController {
    var hideKeyboardTap:UITapGestureRecognizer!
    var keyboardHidden = true
    //get reference
    lazy var fireBaseRef:FIRDatabaseReference = FIRDatabase.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        print(fireBaseRef)
        // Do any additional setup after loading the view.
        
    }

    //handle logout
    func handleLogout() {
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
    }
    
    //set status online or offline when user online or off
    func setStatusOnlineOrOffline(isLogin: Bool, isDisconnect: Bool) {
        if let auth = FIRAuth.auth() {
            
            guard let curUser = auth.currentUser else {
                return
            }
            
            let uid = curUser.uid
            
            self.fireBaseRef.child("Users").child(uid).observeSingleEvent(of: .value, with: { [weak self] (snap) in
                
                guard let strongSelf = self else { return }
                
                if (snap.value is NSNull) {
                    return
                }
                
                guard let userInfo = snap.value as? [String:AnyObject] else {
                    return
                }
                
                guard let realUser = User(uid: uid, JsonData: userInfo) else {
                    return
                }
                
                
                strongSelf.fireBaseRef.child("Users").child(realUser.id).child("isOnline").setValue(isLogin)
                if isLogin{
                    strongSelf.fireBaseRef.child("Users").child(realUser.id).child("lastLogin").setValue("\(NSDate().timeIntervalSince1970)")
                }
                strongSelf.fireBaseRef.child("Users").child(realUser.id).child("isOnline").onDisconnectSetValue(isDisconnect)
                
            })
        }
    }

    //check email
    func isValidEmail(emailStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: emailStr)
    }
    
    //check network
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        
        return isReachable && !needsConnection
        
    }
}
