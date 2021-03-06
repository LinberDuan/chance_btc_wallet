//
//  RealmDBHelper.swift
//  chance_btc_wallet
//
//  Created by Chance on 2016/11/23.
//  Copyright © 2016年 chance. All rights reserved.
//

import UIKit
import RealmSwift

class RealmDBHelper {
    
    static let kRealmDBVersion: UInt64 = 4
    
    //数据库路径
    static var databaseFilePath: URL {
        let fileManager = FileManager.default
        var directoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directoryURL = directoryURL.appendingPathComponent("wallet_data")
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try! fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        return directoryURL
    }
    
    //全局唯一实例
    static var shared: RealmDBHelper = {
        let instance = RealmDBHelper()
        
        return instance
    }()
    
    //数据库操作的监听器
    var notificationToken: NotificationToken? = nil
    
    
    /// 同步数据库文件到icloud上
    func iCloudSynchronize(notification: Realm.Notification? = nil, db: Realm) {
        Log.debug("执行iCloudSynchronize")
        
        //是否开启icloud同步
        if !CHWalletWrapper.enableICloud {
            return
        }
        
        //设置是否登录icloud账号
        if !CloudUtils.shared.iCloud {
            return
        }
        
        //文件
        let fileUrl = db.configuration.fileURL!
        let dbFile = fileUrl.lastPathComponent
        let data = try! Data(contentsOf: fileUrl)

        //建立保存文件的新icloud路径
        let desUrl = CHDocument.getiCloudDocumentURL()!.appendingPathComponent(dbFile)
        Log.debug("icloud目录路径 = \(desUrl)")
        
        //数据库的icloud路径
        let doc = CHDocument(fileURL: desUrl)
        doc.fileContent = data  //导入最新数据到原文件
        
        //同步数据库文件
        doc.save(to: desUrl, for: UIDocumentSaveOperation.forCreating) {
            success in
            Log.debug("save icloud success = \(success)")
            if !success {
                //同步失败
                SVProgressHUD.showError(withStatus: "account synchronize to icloud failed".localized())
            }
        }
        
    }
    
    /// 全局唯一实例, 获取数字货币的交易记录数据库
    var txDB: Realm = {
        // 通过配置打开 Realm 数据库
        var path = CHBTCWallet.transactionDBFilePath
        
        path.appendPathComponent(CHBTCWallet.transactionFileName)
        
        let config = Realm.Configuration(fileURL: path,
                                         schemaVersion: RealmDBHelper.kRealmDBVersion,
                                         migrationBlock: { (migration, oldSchemaVersion) in
                                            if (oldSchemaVersion < RealmDBHelper.kRealmDBVersion) {

                                            }
        })
        let realm = try! Realm(configuration: config)
        return realm
    }()
    

    /// 账户体系数据库
    var acountDB: Realm {
        return try! Realm()
    }
    
    
    /// 检查种子对应的用户体系数据库存不存在
    ///
    /// - Parameter seedHash:
    /// - Returns: 
    func checkRealmForWalletExist(wallet: CHBTCWallet) -> Bool {
        //数据库路径
        var path = wallet.accountDBFilePath
        
        path.appendPathComponent(wallet.accountsFileName)
        
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path.path)
    }
    
    /// 使用钱包的种子哈希切换默认的数据
    ///
    /// - Parameter seedHash: 种子哈希
    func setDefaultRealmForWallet(wallet: CHBTCWallet) {
        // 通过配置打开 Realm 数据库
        var path = wallet.accountDBFilePath
        
        path.appendPathComponent(wallet.accountsFileName)
        let config = Realm.Configuration(fileURL: path,
                                         schemaVersion: RealmDBHelper.kRealmDBVersion,
                                         migrationBlock: { (migration, oldSchemaVersion) in
                                            if (oldSchemaVersion < RealmDBHelper.kRealmDBVersion) {
                                                
                                            }
        })
        //Log.debug("db path = \(path.absoluteString)")
        Realm.Configuration.defaultConfiguration = config
        
        //先停了之前开启的监听器
        self.notificationToken?.invalidate()
        //添加监听时间
        let acountDB = RealmDBHelper.shared.acountDB
        self.notificationToken = acountDB.observe({
            (notification, realm) in
            self.iCloudSynchronize(notification: notification, db: realm)
        })
    }

}

// MARK: - 扩展Results
extension Results {
    
    /**
     转为普通数组
     
     - returns:
     */
    func toArray<T:Object>() -> [T] {
        var arr = [T]()
        for obj in self {
            arr.append(obj as! T)
        }
        return arr
    }
    
}
