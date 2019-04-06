//
//  DeviceViewController.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2017-02-05.
//
//

import UIKit
import SwiftyTeeth
import Foundation

class DeviceViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var charTextField: UITextField!
    @IBOutlet weak var serviceTextField: UITextField!
    
    var device: Device?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let readButton = UIBarButtonItem(title: "Read", style: .plain, target: self, action: #selector(read))
        let subscribeButton = UIBarButtonItem(title: "Subscribe", style: .plain, target: self, action: #selector(subscribe))
        let writeButton = UIBarButtonItem(title: "Write", style: .plain, target: self, action: #selector(write))
        self.navigationItem.rightBarButtonItems = [readButton, subscribeButton, writeButton]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.text = ""
        connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        device?.disconnect()
    }
    
    fileprivate func printUi(_ text: String?) {
        print(text ?? "")
        DispatchQueue.main.async {
            self.textView.text.append((text ?? "") + "\n")
        }
    }
    @IBAction func unSubscribeAction(_ sender: UIButton) {
        self.view.endEditing(true)
        device?.unsubscribe(from: charTextField.text!, in: serviceTextField.text!)
    }
    
}


// MARK: - SwiftyTeethable
extension DeviceViewController {
    func showAlertController(heading:String = "AjayBLE", message : String, actions : [UIAlertAction] = [], delay:Double = 0) {
        let alertCon = UIAlertController(title: heading, message: message, preferredStyle: .alert)
        if actions.count == 0{
            alertCon.addAction(UIAlertAction.init(title: "OK", style: .cancel))
            
        } else {
            for action in actions {
                alertCon.addAction(action)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.present(alertCon, animated: true, completion: {})
        }
    }

    // Connect and iterate through services/characteristics
    func connect() {
        device?.connect(complete: { isConnected in
            guard isConnected == true else {
                return
            }
            self.printUi("App: Device is connected? \(isConnected)")
            print("App: Starting service discovery...")
            self.device?.discoverServices(complete: { result in
                let services = result.value ?? []
                services.forEach {
                    self.printUi("App: Discovering characteristics for service: \($0.uuid.uuidString)")
                    self.device?.discoverCharacteristics(for: $0, complete: { result in
                        let service = result.value?.service
                        let characteristics = result.value?.characteristics ?? []
                        characteristics.forEach {
                            self.printUi("App: Discovered characteristic: \($0.uuid.uuidString) in \(String(describing: service?.uuid.uuidString))")
                        }
                        if service == services.last {
                            self.printUi("App: All services/characteristics discovered")
                        }
                    })
                }
            })

        })
    }
    
    func disconnect() {
        device?.disconnect()
    }
    
    @objc func read() {
        self.view.endEditing(true)
        // Using a Heart-Rate device for testing - this is the HR service and characteristic
        device?.read(from: charTextField.text!, in: serviceTextField.text!, complete: { result in
            if let data = result.value{
                self.printUi("Subscribed value: \(String(describing: String(data: data, encoding: .utf8)))")
            }
        })
    }
    
    @objc func write() {
        self.view.endEditing(true)
        let alertCon = UIAlertController(title: "AjayBLE", message:"", preferredStyle: .alert)
        let noAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in })
        let yesAction = UIAlertAction(title: "Write", style: .default) { (_) -> Void in
            if let command = alertCon.textFields?[0].text?.hexData{
                self.device?.write(data: command, to: self.charTextField.text!, in: self.serviceTextField.text!, complete: { result in
                    self.printUi("Write with response successful? \(result.isSuccess)")
                })
            }
        }
        alertCon.addTextField { (textField) in
            
        }
        alertCon.addAction(noAction)
        alertCon.addAction(yesAction)
        self.present(alertCon, animated: true)
    }
    
    @objc func subscribe() {
        self.view.endEditing(true)
        device?.subscribe(to: charTextField.text!, in: serviceTextField.text!, complete: { result in
            if let data = result.value{
                self.printUi("Subscribed value: \(String(describing: String(data: data, encoding: .utf8)))")
            }
        })
    }
}

extension String {
    var data: Data? {
        var data = Data(capacity: self.count / 2)
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        guard data.count > 0 else { return nil }
        return data
    }
    
    var hexData: Data?{
        let data = Data(self.utf8)
        let hexString = data.map{ String(format:"%02x", $0) }.joined()
        return hexString.data
    }
}

