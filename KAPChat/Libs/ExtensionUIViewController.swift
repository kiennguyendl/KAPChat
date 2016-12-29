//
//  ExtensionUIViewController.swift
//  KAPChat
//
//  Created by Kien Nguyen Dang on 12/8/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase

extension UIViewController {
    var appDelegate:AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // Show Alert without UIAlertAction
    func showAlert(title: String, message: String) {
        let alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    // Show Alert with UIAlertAction
    func showAlert(title: String,msg: String,actions:[UIAlertAction]) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        for action in actions {
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    // Show Alert action sheet
    func showAlertSheet(title: String,msg: String,actions:[UIAlertAction]) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .actionSheet)
        for action in actions {
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // Show error info form Firebase
    func showErrorFirebase(title: String,error: NSError) {
        self.showAlert(title: title, message: error.localizedDescription)
        self.view.isUserInteractionEnabled = true
    }
    
    func startLoading() {
        self.pleaseWait()
        self.view.isUserInteractionEnabled = false
        self.tabBarItem.isEnabled = false
    }
    
    func stopLoading() {
        self.clearAllNotice()
        self.view.isUserInteractionEnabled = true
        self.tabBarItem.isEnabled = true
    }
    
}
