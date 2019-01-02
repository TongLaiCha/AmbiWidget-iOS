//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Milan Sosef on 22/11/2018.
//  Copyright © 2018 tonglaicha. All rights reserved.
//

import UIKit
import NotificationCenter

// TODO:
// 1) Fix the layout incorrect size bug
// 2) Off mode icon is not displayed when setting device to off mode
// DONE 3) Switch the current device displayed
// DONE 4) Open settings page on button click
// DONE 5) Make a file for saving constants

class TodayViewController: UIViewController, NCWidgetProviding {
    var deviceViewModels: [DeviceViewModel]?
    var deviceViewModelIndex: Int = 0
    
    enum SwitchDirection {
        case left
        case right
    }
    
    @IBOutlet weak var modeContentView: UIView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var modeIcon: UIImageView!
    
    // Notification names
    let modeSelection = Notification.Name(rawValue: Constants.modeSelectionNotificationKey)
    let comfortMode = Notification.Name(rawValue: Constants.comfortNotificationKey)
    let temperatureMode = Notification.Name(rawValue: Constants.temperatureNotificationKey)
    let offMode = Notification.Name(rawValue: Constants.offNotificationKey)
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Do any additional setup after loading the view from its nib.
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("viewDidLoad: container size = \(modeContentView.frame.size)")
        createObservers()
        add(ComfortMode(), viewContainer: modeContentView)
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        updateWidget()
        completionHandler(NCUpdateResult.newData)
    }
    
    func updateWidget() {
        // Get deviceList from local storage
        if let localDeviceList = try? DeviceManager.Local.getDeviceList() {
            // Update deviceViewModels
            self.deviceViewModels = localDeviceList.map({ return
                DeviceViewModel(device: $0)})
        }
        updateWidgetViews()
        
        // Get new device data from the API
        DeviceManager.API.getDeviceList()
		.then { newDeviceList in
			DeviceManager.API.getDeviceStatus(for: newDeviceList)
		}.done { updatedDeviceList in
			print("Today View Controller: updatedDeviceList: \(updatedDeviceList)")
			
			// Update deviceViewModels
            self.deviceViewModels = updatedDeviceList.map({ return
                DeviceViewModel(device: $0)})
			
            // Save deviceList to local storage
            try! DeviceManager.Local.saveDeviceList(deviceList: updatedDeviceList)
			self.updateWidgetViews()
        }.catch { error in
            print("Error: \(error)")
        }
    }
    
    public func updateWidgetViews() {
        print("Updating widget views")
        guard let currentDeviceViewModel = deviceViewModels?[deviceViewModelIndex] else {
            // Show loading screen
            return
        }
        
        self.deviceNameLabel.text = currentDeviceViewModel.deviceTitleText
        self.temperatureLabel.text = currentDeviceViewModel.temperatureLabel
        self.humidityLabel.text = currentDeviceViewModel.humidityLabel
        self.modeIcon.image = currentDeviceViewModel.modeIcon
		
        // Set the initial childViewController for the modeContentView.
        add(currentDeviceViewModel.modeSegmentView, viewContainer: modeContentView)
    }

    
    func createObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.switchMode(notification:)), name: modeSelection, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.switchMode(notification:)), name: comfortMode, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.switchMode(notification:)), name: temperatureMode, object: nil)
    }
    
    @objc func switchMode(notification: NSNotification) {
        print("switchmode \(notification.name)")
        // TODO: call mode switch to API, get updated device object, update widget
        let currentDeviceViewModel = deviceViewModels![deviceViewModelIndex]
        switch notification.name {
        case comfortMode:
            currentDeviceViewModel.device.simpleMode = SimpleMode.Comfort
            print("comfort success")
            self.updateWidgetViews()
        case temperatureMode:
            currentDeviceViewModel.device.simpleMode = SimpleMode.Temperature
            self.updateWidgetViews()
        case modeSelection:
            add(ModeSelection(), viewContainer: modeContentView)
        case offMode:
            currentDeviceViewModel.device.simpleMode = SimpleMode.Off
            self.updateWidgetViews()
        default:
            print("Error: notification.name does not match any of the switch cases.")
            break
        }
    }
    
    @IBAction func touchRefreshButton(_ sender: UIButton) {
        self.updateWidgetViews()
    }
    
    @IBAction func touchSettingsButton(_ sender: UIButton) {
        print("Settings button clicked")
        
        let myAppUrl = NSURL(string: "widgetcontainingapp://")!
        extensionContext?.open(myAppUrl as URL, completionHandler: { (success) in
            if (!success) {
                // let the user know it failed
                print("Error: something went wrong when tried opening the app...")
            }
        })
    }
    
    @IBAction func touchSwitchDeviceButton(_ sender: UIButton) {
        var direction: SwitchDirection
        
        if sender.tag == 6 {
            direction = .left
            switchDevice(with: direction)
        } else if sender.tag == 7 {
            direction = .right
            switchDevice(with: direction)
        }
        
    }
    
    func switchDevice(with direction: SwitchDirection) {
        switch direction {
        case .left:
            if deviceViewModelIndex + 1 == deviceViewModels!.endIndex {
                deviceViewModelIndex = 0
            } else {
                deviceViewModelIndex += 1
            }
        case .right:
            if deviceViewModelIndex - 1 < deviceViewModels!.startIndex {
                deviceViewModelIndex = deviceViewModels!.endIndex - 1
            } else {
                deviceViewModelIndex -= 1
            }
        }
		
		// Update view with old local data
		self.updateWidgetViews()
		print("Updated view with old (local) device status.")
		
		// Async call to update with new data
		DeviceManager.API.getDeviceStatus(for: deviceViewModels![deviceViewModelIndex].device)
		.done { deviceStatus in
			self.deviceViewModels![self.deviceViewModelIndex].device.status = deviceStatus
			self.updateWidgetViews()
			print("Updated view with new device status.")
			
		}.catch { error in
			print("Error: \(error)")
		}
    }
    
}

extension UIViewController {
    func add(_ child: UIViewController, viewContainer: UIView) {
        addChild(child)
        viewContainer.addSubview(child.view)
        child.didMove(toParent: self)
    }
    func remove() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
}
