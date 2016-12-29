//
//  LoginViewController.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/7/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: BaseNonAuthenticatedViewController {
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtMatkhau: UITextField!
    @IBOutlet weak var btnDangNhap: UIButton!
    @IBOutlet weak var btnLuumatkhau: UIButton!
    
    // check button save login
    var isChecked: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtEmail.becomeFirstResponder()
        txtMatkhau.isSecureTextEntry = true
        btnDangNhap.layer.masksToBounds = true
        btnDangNhap.layer.cornerRadius = 10
        
        //check user default exitsted
        if UserDefaults.standard.value(forKey: "userInfo") != nil{
            self.startLoading()
            btnLuumatkhau.setImage(UIImage(named: "checked"), for: .normal)
            let userInfo = UserDefaults.standard.object(forKey: "userInfo") as? [String: String] ?? [String: String]()
            print(userInfo)
            for (key , value) in userInfo{
                print("\(key) -> \(value)")
                if key == "email"{
                    txtEmail.text = value
                }else{
                    txtMatkhau.text = value
                }
            }
            self.stopLoading()
        }
        
    }
    
    @IBAction func btnDangnhap(_ sender: Any) {
        if self.isConnectedToNetwork(){
            
            self.startLoading()
            guard let email = txtEmail.text, let password = txtMatkhau.text else {
                self.stopLoading()
                return
            }
            
            // check validata value
            if checkValidateValue() {
                FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                    if let error = error {
                        self.stopLoading()
                        self.showErrorFirebase(title: "Lỗi mạng", error: error as NSError)
                    }
                    
                    if let _ = user{
                        //save user info into User Default
                        if self.isChecked{
                            UserDefaults.standard.removeObject(forKey: "userInfo")
                            let value = ["email":email, "pw": password]
                            UserDefaults.standard.set(value, forKey: "userInfo")
                            UserDefaults.standard.synchronize()
                        }
                        self.txtEmail.text = ""
                        self.txtMatkhau.text = ""
                        self.setStatusOnlineOrOffline(isLogin: true, isDisconnect: false)
                        //self.stopLoading()
                        let uid = FIRAuth.auth()!.currentUser!.uid
                        DatabaseManager.shareInstance.startApp(uid: uid)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.pushHome), name: NSNotification.Name(rawValue: "SuccessLoading"), object: nil)

                        
                        
                    }
                })
            }else{
                self.showAlert(title: "Opps", message: "Đăng nhập không thành công!")
                self.stopLoading()
                return
            }

        }
        else{
            self.showAlert(title: "Lỗi mạng", message: "Vui lòng kiểm tra mạng")
        }
        
        
}
    func pushHome(){
        let vc = HomeViewController()
        self.navigationController?.pushViewController(vc, animated: true)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "SuccessLoading"), object: nil)
        self.stopLoading()
    }
    
    func checkValidateValue() -> Bool {
        guard let email:String = txtEmail.text,
            let pw:String = txtMatkhau.text
            else { return false }
        
        if email == "" {
            showAlert(title: "Login", message: "Vui lòng nhập email")
            txtEmail.becomeFirstResponder()
            return false
        } else if !isValidEmail(emailStr: email) {
            txtEmail.text = ""
            txtEmail.becomeFirstResponder()
            showAlert(title: "Login", message: "Địa chỉ email sai")
            return false
        }
        
        if pw == "" {
            txtMatkhau.becomeFirstResponder()
            showAlert(title: "Login", message: "Vui lòng điền mật khẩu")
            return false
        }
        
        return true
        
    }
    
    @IBAction func btnQuaylai(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "userInfo")
        let vc = RegisterViewController()
        self.present(vc, animated: true, completion: nil)
    }
    
    //save password if checked
    @IBAction func btnSavePassWord(_ sender: Any) {
        
        if UserDefaults.standard.value(forKey: "userInfo") == nil{
            if isChecked{
                isChecked = false
                btnLuumatkhau.setImage(nil, for: .normal)
            }else{
                isChecked = true
                btnLuumatkhau.setImage(UIImage(named: "checked"), for: .normal)
            }
        }else{
            isChecked = false
            UserDefaults.standard.removeObject(forKey: "userInfo")
            btnLuumatkhau.setImage(nil, for: .normal)
        }
        
    }
    
    
}
