//
//  SelectNetworkViewController.swift
//  Nimble
//
//  Created by Mike on 12/1/17.
//

import UIKit

public class SelectNetworkViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    NetworkCredentialsTransferManagerDelegate {
    
    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loaderView = LoaderView(frame: .zero)
    
    // Communication
    fileprivate var transferManager: NetworkCredentialsTransferManager?
    fileprivate var communicationManager: DeviceCommunicationManager? = DeviceCommunicationManager()
    
    // Internal data
    fileprivate var networks: [Network] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loaderView.show("Looking for networks")
        
        scanForNetworks { foundNetworks in
            self.networks = foundNetworks
            self.loaderView.hide()
        }
    }
    
    // MARK: - Setup
    
    private func setup() {
        view.backgroundColor = .white

        setupTableView()
        setupLoaderView()
    }
    
    private func setupTableView() {
        let margins = view.layoutMarginsGuide
        
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -15.0).isActive = true
        tableView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 15.0).isActive = true
        tableView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
        
        tableView.register(NetworkCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupLoaderView() {
        let margins = view.layoutMarginsGuide
        
        view.addSubview(loaderView)
        
        loaderView.translatesAutoresizingMaskIntoConstraints = false
        loaderView.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
        loaderView.centerYAnchor.constraint(equalTo: margins.centerYAnchor, constant: -50.0).isActive = true
    }
    
    private func scanForNetworks(completion: @escaping ([Network]) -> Void) {
        
        // TODO: Retry logic (auto or manual)
    
        communicationManager?.sendCommand(Command.ScanAP.self) { result in
            switch result {
            case .success(let list):
                completion(list)
            case .failure(let error):
                print(error)
            }
            self.communicationManager = nil
        }
    }
    
    private func transferCredentials(`for` network: Network) {
        loaderView.show("Transferring credentials")
        
        transferManager = NetworkCredentialsTransferManager()
        transferManager?.delegate = self
        transferManager?.transferCredentials(for: network)
    }
}

// MARK: - UITableViewDataSource

extension SelectNetworkViewController {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return networks.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NetworkCell
        cell.network = networks[indexPath.row]
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SelectNetworkViewController {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let network = networks[indexPath.row]
        
        if network.securityType != .open {
            UI.presentPasswordDialog(for: network, in: self) { alertController in
                if let textFields = alertController.textFields,
                    let passwordField = textFields.first,
                    let password = passwordField.text
                {
                    var mutableNetwork = network
                    mutableNetwork.password = password
                    
                    self.transferCredentials(for: mutableNetwork)
                }
            }
        } else {
            transferCredentials(for: network)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NetworkCredentialsTransferManagerDelegate

extension SelectNetworkViewController {
    func networkCredentialsTransferManagerDidConnectDeviceToNetwork(_ manager: NetworkCredentialsTransferManager) {
        transferManager = nil // we're done using this
        loaderView.setText("Connecting to network")
        
        Wifi.shared.monitorForDisconnectingNetwork {
            self.loaderView.hide("Connected!")
            Wifi.shared.monitorForNetworkReachability {
                print("we got this!")
            }
        }
    }
}
