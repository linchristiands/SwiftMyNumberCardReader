//
//  ViewController.swift
//  felica-reader
//
//  Created by treastrain on 2019/06/06.
//  Copyright © 2019 treastrain / Tanaka Ryoga. All rights reserved.
//

import UIKit
import CoreNFC
import libjeid

class ViewController: UIViewController, NFCTagReaderSessionDelegate {

    @IBOutlet weak var Pin: UITextField!
    @IBOutlet weak var idImageView: UIImageView!
    @IBOutlet weak var nameImageView: UIImageView!
    @IBOutlet weak var addressImageView: UIImageView!
    
    @IBOutlet weak var
nameLabel:UILabel!
    @IBOutlet weak var
addressLabel:UILabel!
    @IBOutlet weak var
birthdayLabel:UILabel!
    @IBOutlet weak var
sexLabel:UILabel!
    var session: NFCTagReaderSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func beginScanning(_ sender: UIButton) {
        guard NFCTagReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        self.session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: DispatchQueue.global())
        self.session?.alertMessage = "Hold your iPhone near the item to learn more about it."
        self.session?.begin()
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("tagReaderSessionDidBecomeActive(_:)")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertController = UIAlertController(
                    title: "Session Invalidated",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        self.session = nil
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        print("tagReaderSession(_:didDetect:)")
        print("reader session thread: \(Thread.current)")
        
        let tag = tags.first!
        session.connect(to:tag){(error:Error?)in
            do {
                let pincode:String=self.Pin.text!
                if (pincode.isEmpty || pincode.count != 4) {
                    session.invalidate(errorMessage: "証番号が入力されていません")
                    return
                    
                }
                DispatchQueue.main.sync {
                    self.Pin.text=nil
                }
                let reader = try JeidReader(tag)
                session.alertMessage = "読み取り開始..."
                let ap = try reader.selectINText()
                
                // 暗証番号を入力
                do {
                    
                    try ap.verifyPin(pincode)
                } catch let jeidError as JeidError {
                    if case .invalidPin(let counter) = jeidError {
                        if jeidError.isBlocked! {
                            session.invalidate(errorMessage: "PINがブロックされています")
                        } else {
                            session.invalidate(errorMessage: "PINが間違っています。残り回数: \(counter)")
                        }
                        return
                    }
                }
                // Filesオブジェクトの読み出し
                let files = try ap.readFiles()
                
                // Filesオブジェクトから4情報を取得
                let attrs = try files.getAttributes()
                
                let apVisual = try reader.selectINVisual()
                try apVisual.verifyPin(pincode)
                let visualFiles=try apVisual.readFiles()
                let entries=try visualFiles.getEntries()
                let idPhotoImage=UIImage(data:entries.photoData!)
                let addressImage=UIImage(data:entries.address!)
                let nameImage=UIImage(data:entries.name!)
                session.alertMessage = "読み取り完了！"
                DispatchQueue.main.sync {
                    self.nameLabel.text=attrs.name!
                    self.addressLabel.text=attrs.address!
                    self.birthdayLabel.text=attrs.birthDate!
                    self.sexLabel.text=attrs.sexString!
                    self.idImageView.image=idPhotoImage
                    self.addressImageView.image=addressImage
                    self.nameImageView.image=nameImage
                }
                
                session.invalidate()
            } catch {
                print(error)
                session.invalidate(errorMessage: "読み取りエラー")
            }
        }
    }
}





