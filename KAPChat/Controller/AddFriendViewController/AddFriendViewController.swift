//
//  AddFriendViewController.swift
//  KAPChat
//
//  Created by Kien Nguyen Dang on 12/12/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase
class AddFriendViewController: BaseAuthenticatedViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var btnTimkiem: UIButton!
    var uid: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        btnTimkiem.layer.masksToBounds = true
        btnTimkiem.layer.cornerRadius = 10
        txtEmail.layer.masksToBounds = true
        txtEmail.layer.cornerRadius = 20
        txtEmail.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }

    
    @IBAction func btnTimkiem(_ sender: Any) {
        self.startLoading()
        
        guard let email = txtEmail.text else {
            self.stopLoading()
            return
        }
        
        if checkValidateValue(){
            self.fireBaseRef.database.reference().child("Users").observeSingleEvent(of: .value, with: { (snap: FIRDataSnapshot) in
                if let listUserSnapshot:[FIRDataSnapshot] = snap.children.allObjects as? [FIRDataSnapshot]{
                    if listUserSnapshot.count > 0{
                        for userSnapshot in listUserSnapshot{
                            let emailAdd = userSnapshot.childSnapshot(forPath: "email").value as! String
                            if emailAdd == email{
                                self.uid = userSnapshot.key
                                self.stopLoading()
                                let vc = TimeLineUserViewController()
                                vc.uid = self.uid
                                vc.email = self.txtEmail.text
                                self.navigationController?.pushViewController(vc, animated: true)
                                break
                            }
                        }
                    }
                }
                
            })
            
        }
        else{
            self.stopLoading()
            showAlert(title: "Tìm kiếm", message: "Không tìm thấy thông tin tài khoản")
        }

        self.stopLoading()
    }
    
    func checkValidateValue() -> Bool {
        guard let email = txtEmail.text else{
            return false
        }
        
        if email == ""{
            showAlert(title: "Login", message: "Vui lòng nhâp email")
            txtEmail.text = ""
            txtEmail.becomeFirstResponder()
            return false
        }
        
        if !self.isValidEmail(emailStr: email){
            txtEmail.text = ""
            showAlert(title: "Login", message: "Định dạng email không đúng, vui lòng nhập lại")
            txtEmail.becomeFirstResponder()
            return false
        }
        
        return true
    }
}
