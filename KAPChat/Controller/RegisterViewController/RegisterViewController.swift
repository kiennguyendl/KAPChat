//
//  RegisterViewController.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/7/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: BaseNonAuthenticatedViewController {

    
    @IBOutlet weak var txtHoten: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtMatkhau: UITextField!
    @IBOutlet weak var txtNhaplaimatkhau: UITextField!
    @IBOutlet weak var btnDangky: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "REGISTER"
        txtHoten.becomeFirstResponder()
        txtMatkhau.isSecureTextEntry = true
        txtNhaplaimatkhau.isSecureTextEntry = true
        
        btnDangky.layer.masksToBounds = true
        btnDangky.layer.cornerRadius = 10
    }
    
    @IBAction func btnDangky(_ sender: Any) {
        if self.isConnectedToNetwork(){
            self.startLoading()
            guard let name = txtHoten.text, let email = txtEmail.text, let pw = txtMatkhau.text else {
                self.stopLoading()
                return
            }
            
            //check invalidate Info
            if checkInvalidateInfo(){
                
                FIRAuth.auth()?.createUser(withEmail: email, password: pw, completion: { (user: FIRUser?, error) in
                    if let error = error {
                        self.stopLoading()
                        self.showErrorFirebase(title: "Đăng ký", error: error as NSError)
                    }else if let user = user{
                        let updateUser = user.profileChangeRequest()
                        updateUser.displayName = name
                        if let photoURL: URL = URL(string: User.default_avt){
                            updateUser.photoURL = photoURL
                            //save user into firebase
                            self.addUserIntoDatabase(user: user, updateUser: updateUser, name: name, email: email, imgUrlStr: photoURL.absoluteString )
                            self.handleLogout()
                            self.stopLoading()
                            let alertController = UIAlertController(title: "Thông báo", message: "Bạn đăng ký tài khoản thành công. Vui lòng xác thực và đăng nhập.", preferredStyle:UIAlertControllerStyle.alert)
                            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak self](UIAlertAction) in
                                self?.dismiss(animated: true, completion: nil)
                            }))
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                })
                
                
                
                
                
            }else {
                self.stopLoading()
                return
            }
        }else{
            self.showAlert(title: "Lỗi mạng", message: "Vui lòng kiểm tra mạng")
        }
    }
    
    
    
    @IBAction func btnQuaylai(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //add user info into firebase
    func addUserIntoDatabase(user: FIRUser, updateUser: FIRUserProfileChangeRequest, name: String, email: String, imgUrlStr: String){
        updateUser.commitChanges { (error) in
            if let error = error {
                self.stopLoading()
                self.showAlert(title: "Lổi thêm người dùng", message: error.localizedDescription)
            }else{
                let userInfo:[String:AnyObject] = [
                    "displayName"       : name as AnyObject,
                    "email"             : email as AnyObject,
                    "avatarUrl"            : imgUrlStr as AnyObject,
                    "created_date_1970" : "\(NSDate().timeIntervalSince1970)" as AnyObject,
                    "provider"          : user.providerID as AnyObject,
                    "status"            : "" as AnyObject,
                    "lastLogin"         : "\(NSDate().timeIntervalSince1970)" as AnyObject,
                    "isOnline"          : false as AnyObject
                ]
                
                self.addUserInfo(user: user, userInfo: userInfo)
                self.stopLoading()
            }
        }
    }
    func checkInvalidateInfo() -> Bool {
        guard let name:String = self.txtHoten.text,
            let email:String = self.txtEmail.text,
            let pw:String = self.txtMatkhau.text,
            let inputPWAgain = self.txtNhaplaimatkhau.text
            else {
                return false
        }
        
        if name == "" {
            txtHoten.becomeFirstResponder()
            showAlert(title: "Đăng ký", message: "Vui lòng nhập họ tên")
            return false
        }
        
        if email == "" {
            txtEmail.becomeFirstResponder()
            showAlert(title: "Đăng ký", message: "Vui lòng nhập email")
            return false
        } else if !isValidEmail(emailStr: email) {
            txtEmail.text = ""
            txtEmail.becomeFirstResponder()
            showAlert(title: "Đăng ký", message: "Địa chì email không đúng định dạng")
            return false
        }
        
        if pw == "" {
            txtMatkhau.becomeFirstResponder()
            showAlert(title: "Đăng ký", message: "Vui lòng nhập mật khẩu")
            return false
        }
        
        if inputPWAgain == ""{
            txtNhaplaimatkhau.becomeFirstResponder()
            showAlert(title: "Đăng ký", message: "Vui lòng nhập lại mật khẩu")
            return false
        }
        
        if pw != inputPWAgain{
            self.stopLoading()
            txtNhaplaimatkhau.text = ""
            txtNhaplaimatkhau.becomeFirstResponder()
            showAlert(title: "Đăng ký", message: "Mật khẩu không giống nhau")
            return false
        }
        return true
    }

}
