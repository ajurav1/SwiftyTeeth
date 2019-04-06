//
//  DeviceListViewController.swift
//  SwiftyTeeth Sample
//
//  Created by Basem Emara on 10/27/16.
//
//

import UIKit
import SwiftyTeeth

class DeviceListViewController: UITableViewController {
    
    fileprivate var devices = [Device]()
    static let segue = "goToDevice"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scanButton = UIBarButtonItem(title: "Scan", style: .plain, target: self, action: #selector(scanTapped))
        self.navigationItem.rightBarButtonItem = scanButton
        
        swiftyTeeth.stateChangedHandler = { (state) in
            print("Bluetooth State is: \(state)")
        }
    }
}


// MARK: - SwiftyTeethable
extension DeviceListViewController: SwiftyTeethable {
    @objc func scanTapped() {
        // TODO: Use the changes API to update the list
        swiftyTeeth.scan(for: 5) { devices in
            self.devices = devices
            self.tableView.reloadData()
        }
    }
}


// MARK: - Segues
extension DeviceListViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == DeviceListViewController.segue,
            let destination = segue.destination as? DeviceViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = self.tableView.indexPath(for: cell) else {
                return
        }
        
        let device = devices[indexPath.row]
        destination.device = device
    }    
}


// MARK: - UITableViewDataSource
extension DeviceListViewController {
    
    static let cellIdentifier = "cellIdentifier"
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceListViewController.cellIdentifier, for: indexPath)
        
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = device.id
        return cell
    }
}
