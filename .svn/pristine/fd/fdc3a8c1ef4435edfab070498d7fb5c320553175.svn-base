//
//  PhotoViewController.swift
//  KAPChat
//
//  Created by Tuan anh Dang on 12/16/16.
//  Copyright © 2016 Kien Nguyen Dang. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {

    @IBOutlet weak var imgPhoto: UIImageView!
    
    var photoUrl: String?
    
    @IBAction func touchClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.pleaseWait()
        guard let photoUrl = self.photoUrl else { return }
        
        DispatchQueue.global().async {
            if let url = URL(string: photoUrl) {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if let img = UIImage(data: data) {
                            
                            //                            let resultImg = img.scaleImage(newSize: newSize).createRadius(newSize: newSize, radius: 22, byRoundingCorners: .allCorners)
                            self.imgPhoto.image = img
                            self.clearAllNotice()
                        }
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
