//
//  PasswordModifyViewController.swift
//  bitbank_wallet
//
//  Created by 麦志泉 on 16/2/1.
//  Copyright © 2016年 bitbank. All rights reserved.
//

import UIKit

class PasswordModifyViewController: UITableViewController {
    
    //MARK: - 成员变量
    @IBOutlet var textFieldOldPassword: UITextField!
    @IBOutlet var textFieldNewPassword: UITextField!
    @IBOutlet var textFieldConfirmPassword: UITextField!
    @IBOutlet var buttonSave: UIButton!
    
    @IBOutlet var tableViewCellOldPassword: UITableViewCell!
    @IBOutlet var tableViewCellNewPassword: UITableViewCell!
    @IBOutlet var tableViewCellConfirmPassword: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// MARK: - 控制器方法
extension PasswordModifyViewController {
    
    /**
     配置UI
     */
    func setupUI() {
        
        self.navigationItem.title = "Password Setting".localized()
        
        //按钮样式
        self.buttonSave.layer.cornerRadius = 4
        self.buttonSave.layer.masksToBounds = true
        self.buttonSave.setBackgroundImage(UIColor.imageWithColor(UIColor(hex: 0xDB2427)), for: UIControlState())
    }
    
    //检测输入值是否合法
    func checkValue() -> Bool {
        if CHBTCWallets.sharedInstance.password != "" {
            if self.textFieldOldPassword.text!.isEmpty {
                SVProgressHUD.showInfo(withStatus: "Old password is empty".localized())
                return false
            }
        }
        
        if self.textFieldNewPassword.text!.isEmpty {
            SVProgressHUD.showInfo(withStatus: "New password is empty".localized())
            return false
        }
        if self.textFieldConfirmPassword.text != self.textFieldNewPassword.text! {
            SVProgressHUD.showInfo(withStatus: "Passwords is different".localized())
            return false
        }
        
        return true
    }
    
    /**
     点击保存
     
     - parameter sender:
     */
    @IBAction func handleSavePress(_ sender: AnyObject?) {
        if self.checkValue() {
            let password = self.textFieldNewPassword.text!.trim()
            CHBTCWallets.sharedInstance.password = password
            SVProgressHUD.showSuccess(withStatus: "Password reset successed".localized())
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    
}

// MARK: - 文本输入框代理方法
extension PasswordModifyViewController: UITextFieldDelegate {
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === self.textFieldOldPassword {
            self.textFieldNewPassword.becomeFirstResponder()
        } else if textField == self.textFieldNewPassword {
            textFieldConfirmPassword.becomeFirstResponder()
        } else if textField == self.textFieldConfirmPassword {
            textFieldConfirmPassword.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxCharOfPassword = 50
        
        if(textField == self.textFieldOldPassword
            || textField == self.textFieldNewPassword
            || textField == self.textFieldConfirmPassword) {
                if (range.location>(maxCharOfPassword - 1)) {
                    return false
                }
        }
        
        
        return true;
    }
    
}

extension PasswordModifyViewController {
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if CHBTCWallets.sharedInstance.password == "" {
            return 2
        } else {
            return 3
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if CHBTCWallets.sharedInstance.password == "" {
                return self.tableViewCellNewPassword
            } else {
                return self.tableViewCellOldPassword
            }
            
        } else if indexPath.row == 1 {
            if CHBTCWallets.sharedInstance.password == "" {
                return self.tableViewCellConfirmPassword
            } else {
                return self.tableViewCellNewPassword
            }
        } else {
            return self.tableViewCellConfirmPassword
        }
    }
}