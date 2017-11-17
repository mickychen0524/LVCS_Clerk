//
//  PendingViewController.swift
//  StoreClerkLite
//
//  Created by Administrator on 9/6/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import FSDK

class PendingViewController: UIViewController {

    @IBOutlet weak var pendingCollectionView: UICollectionView!
    
    var peers: [MCPeerID: DeviceModel] = [:]
    let serviceManager = ServiceManager.getManager(t: "clerk")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        serviceManager.delegate = self
        if serviceManager.getClientList().count > 0 {
            peers = serviceManager.getClientList()
            pendingCollectionView.reloadData()
            serviceManager.playSound()
        }
    }
    
    func startCall() {
        if let callViewController = storyboard?.instantiateViewController(withIdentifier: "CallViewController") as? CallViewController {
            present(callViewController, animated: true, completion: nil)
        }
    }

    
    @IBAction func back(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension PendingViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return peers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PendingCell", for: indexPath) as! PendingCollectionViewCell
        let peer = peers[indexPath.row].key
        cell.nameLabel.text = peer.displayName
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.size.width - 40) / 3
        return CGSize(width: width, height: width * 1.3)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("clicked initiating")
        serviceManager.stopSound()
        serviceManager.callRequest("incomingCall", index: peers[indexPath.row].key)
    }
}

extension PendingViewController: ServiceManagerProtocol {
    
    func connectedDevicesChanged(_ manager: ServiceManager, connectedDevices: [MCPeerID: DeviceModel]) {
        DispatchQueue.main.async {
            self.peers = connectedDevices
            self.pendingCollectionView.reloadData()
        }
    }
    
    
    func receivedData(_ manager: ServiceManager, peerID: MCPeerID, responseString: String) {
        DispatchQueue.main.async {
            switch responseString {
            case ResponseValue.incomingCall.rawValue :
                print("incomingCall")
            case ResponseValue.callAccepted.rawValue:
                print("callAccepted")
                self.startCall()
            case ResponseValue.callRejected.rawValue:
                print("callRejected")
            default:
                print("Unknown color value received: \(responseString)")
            }
        }
    }
}
