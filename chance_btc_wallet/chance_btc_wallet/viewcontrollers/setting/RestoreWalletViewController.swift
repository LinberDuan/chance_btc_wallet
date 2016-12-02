//
//  RestoreWalletViewController.swift
//  chance_btc_wallet
//
//  Created by Chance on 2016/11/29.
//  Copyright © 2016年 chance. All rights reserved.
//

import UIKit

class RestoreWalletViewController: BaseTableViewController {
    
    @IBOutlet var textViewRestore: CHTextView!
    
    @IBOutlet var buttonConfirm: CHButton!
    @IBOutlet var labelTips: UILabel!
    
    var isRestore = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //首先验证警告一下用户这是一个非常危险的操作，会完全破坏整个HDM钱包的用户信息。
        //TODO:
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


// MARK: - 控制器方法
extension RestoreWalletViewController {
    
    
    /// 配置UI
    func setupUI() {
        //默认不可用
        self.buttonConfirm.isEnabled = false
        
        //是否操作恢复钱包
        if isRestore {
            self.buttonConfirm.isHidden = false
            self.labelTips.text = "Warning：Your current wallet will be removed if your confirm to restore that you inputed".localized()
            self.textViewRestore.isEditable = true
    
        } else {
            self.buttonConfirm.isHidden = true
            //请写下密语，并安全保管好，不要随便给别人，以后钱包程序丢失，可通过密语恢复
            self.labelTips.text = "Please mark down this passphrase and safe keeping. Don't give them to anybody. You can restore wallet by this passphrase when you lose you wallet.".localized()
            
            self.textViewRestore.isEditable = false
            //显示恢复密语
            self.textViewRestore.text = CHBTCWallet.sharedInstance.passphrase
            Log.debug("passphrase = \(self.textViewRestore.text!)")
        }
    }
    
    @IBAction func handleRestorePress(_ sender: CHButton) {
        sender.isEnabled = false
        //1.输入恢复密码，可为空
        self.showPasswordTextAlert { (password) in
            
            //2.根据导入的密语获取HD钱包
            
            let phrase = self.textViewRestore.text!.trim()
            //创建钱包但不重建表
            guard let wallet = CHBTCWallet.sharedInstance.createWallet(phrase,
                                                        password: password,
                                                        isDropTable: false) else {
                SVProgressHUD.showError(withStatus: "Create wallet failed".localized())
                sender.isEnabled = true
                return
            }
            
            var account = wallet.getAccount()
            
            if account == nil {
                
                //3.HDM钱包的账户体系是一个内置的系统，账户信息没法复原，只能初始第一个账户
                account = wallet.createHDAccount(by: "Account 1")
                
                if account == nil {
                    SVProgressHUD.showError(withStatus: "Create wallet account failed".localized())
                    sender.isEnabled = true
                    return
                }
                
                CHBTCWallet.sharedInstance.selectedAccountIndex = account!.index
                CHBTCWallet.sharedInstance.password = password
                
                //让用户重置昵称
                self.showNicknameTextAlert(complete: { (nickname) in
                    let realm = RealmDBHelper.acountDB
                    try! realm.write {
                        account!.userNickname = nickname
                    }
                    SVProgressHUD.showSuccess(withStatus: "The wallet have been restore successfully".localized())
                    _ = self.navigationController?.popViewController(animated: true)
                })
            } else {
                
                //设置密码和当前的首个用户
                CHBTCWallet.sharedInstance.selectedAccountIndex = account!.index
                CHBTCWallet.sharedInstance.password = password
                
                SVProgressHUD.showSuccess(withStatus: "The wallet have been restore successfully".localized())
                _ = self.navigationController?.popViewController(animated: true)
            }
        }

    }
    
    
    /// 弹出恢复密码输入框
    ///
    /// - Parameter complete: 回调
    func showPasswordTextAlert(complete: @escaping (_ password: String) -> Void) {
        //弹出密码输入框
        let alertController = UIAlertController(title: "The passphrase's password".localized(),
                                                message: "Input the password if the passphrase has",
                                                preferredStyle: .alert)
        
        alertController.addTextField {
            (textField: UITextField!) -> Void in
            textField.placeholder = "Input passphrase's password".localized()
            textField.isSecureTextEntry = true
        }
        
        let settingsAction = UIAlertAction(title: "Restore".localized(), style: .default) { (alertAction) in
            let password = alertController.textFields![0]
            complete(password.text!.trim())
            
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    /// 重置昵称
    ///
    /// - Parameter complete:
    func showNicknameTextAlert(complete: @escaping (_ nickname: String) -> Void) {
        //弹出昵称输入框
        let alertController = UIAlertController(title: "Restore wallet successfully".localized(),
                                                message: "Set a new account name",
                                                preferredStyle: .alert)
        
        alertController.addTextField {
            (textField: UITextField!) -> Void in
            textField.placeholder = "Input account name".localized()
            textField.isSecureTextEntry = false
        }
        
        let settingsAction = UIAlertAction(title: "Save".localized(), style: .default) { (alertAction) in
            let nickname = alertController.textFields![0]
            complete(nickname.text!.trim())
            
        }
        alertController.addAction(settingsAction)
        
//        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
//        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}


// MARK: - 实现TextView委托方法
extension RestoreWalletViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        self.buttonConfirm.isEnabled = !textView.text.isEmpty
    }
    
}