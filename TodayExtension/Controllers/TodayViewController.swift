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
// 1)

class TodayViewController: UIViewController, NCWidgetProviding {
    var deviceViewModels: [DeviceViewModel]?
	var currentDeviceId: String? {
		get {
			return UserDefaults(suiteName: UserDefaultsKeys.currentDeviceId)!.string(forKey: UserDefaultsKeys.currentDeviceId)
		}
		set(newValue) {
			UserDefaults(suiteName: UserDefaultsKeys.currentDeviceId)!.set(newValue, forKey: UserDefaultsKeys.currentDeviceId)
		}
	}
    
    enum SwitchDirection {
        case left
        case right
    }
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var modeIcon: UIImageView!
    @IBOutlet weak var bitWarmButton: UIButton!
    @IBOutlet weak var bitColdButton: UIButton!
    @IBOutlet weak var comfortButton: UIButton!
    @IBOutlet weak var offButton: UIButton!
    
    @IBOutlet weak var buttonRow: UIStackView!
    @IBOutlet weak var mainView: UIStackView!
    
    var loadingViewController = LoadingViewController()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Do any additional setup after loading the view from its nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        
        add(loadingViewController)
        loadingViewController.view.isHidden = true
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.buttonRow.isHidden = true
            self.preferredContentSize = maxSize
        } else if activeDisplayMode == .expanded {
            self.buttonRow.isHidden = false
            self.preferredContentSize = CGSize(width: maxSize.width, height: 220)
        }
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        updateWidgetViews()
        updateLocalDeviceList()
        completionHandler(NCUpdateResult.newData)
    }
    
    public func updateWidgetViews() {
        print("Updating widget views")
        
        // Get deviceList from local storage.
        guard let localDeviceList = try? DeviceManager.Local.getDeviceList() else {
            // TODO: Show loading screen
            return
        }
        
        // Update deviceViewModels from local storage.
        self.deviceViewModels = localDeviceList.map({ return
            DeviceViewModel(device: $0)})
		
		// If no current device view model is set AND no default could be set
		guard let currentDeviceViewModel = getCurrentDeviceViewModel() else {
			return
		}
        
        self.deviceNameLabel.text = currentDeviceViewModel.deviceTitleText
        self.locationNameLabel.text = currentDeviceViewModel.locationNameText
        self.temperatureLabel.text = currentDeviceViewModel.temperatureLabel
        self.humidityLabel.text = currentDeviceViewModel.humidityLabel
        self.modeIcon.image = currentDeviceViewModel.modeIcon
        
        print("Updated view with local device status.")
    }
    
    func updateLocalDeviceList() {
        print("Updating local device list")
        mainView.isHidden = true
        self.loadingViewController.view.isHidden = false
        
        // Get new device data from the API
        DeviceManager.API.getDeviceList()
            .then { newDeviceList in
                DeviceManager.API.getDeviceStatus(for: newDeviceList)
            }.done { updatedDeviceList in
                
                // Save deviceList to local storage
                try! DeviceManager.Local.saveDeviceList(deviceList: updatedDeviceList)
                
                // Update widget views
                self.updateWidgetViews()
                self.mainView.isHidden = false
                self.loadingViewController.view.isHidden = true
            
            }.catch { error in
                print("Error: \(error)")
        }
    }
	
	//
	// Gets the current device view model based on the currentDeviceId
	// will look for the current device in [deviceViewModels]
	//
	func getCurrentDeviceViewModel() -> DeviceViewModel? {
		var deviceViewModel: DeviceViewModel?
		
		// If no deviceViewModels exist, return nil
		if deviceViewModels == nil { return nil }
		if deviceViewModels!.count < 1 { return nil }
		
		// Look for current device view model based on id
		for i in 0..<self.deviceViewModels!.count {
			if self.deviceViewModels![i].device.id == currentDeviceId {
				deviceViewModel = self.deviceViewModels![i]
			}
		}
		
		if deviceViewModel == nil {
			deviceViewModel = deviceViewModels![0]
			currentDeviceId = deviceViewModels![0].device.id
			print("currentDeviceViewModel not found, using default index 0")
		}
		
		return deviceViewModel
	}
	
	func getCurrentDeviceViewModelIndex() -> Int {
		var index: Int = 0
		for i in 0..<self.deviceViewModels!.count {
			if self.deviceViewModels![i].device.id == currentDeviceId {
				index = i
			}
		}
		return index
	}
	
	func updateCurrentDevice() {
		print("Updating current device list")
		
		guard let currentDeviceViewModel = getCurrentDeviceViewModel() else {
			print("Could not update current device, currentDeviceViewModel not found")
			return
		}
		
		// Get new device data from the API
		DeviceManager.API.getDeviceStatus(for: currentDeviceViewModel.device)
		.done { newDeviceSatus in
			
			// Get current deviceList
			let deviceList = try! DeviceManager.Local.getDeviceList()
			
			// Update devicelist with new device status data
			var updatedDeviceList = deviceList
			for i in 0..<deviceList.count {
				if deviceList[i].id == currentDeviceViewModel.device.id {
					updatedDeviceList[i].status = newDeviceSatus
				}
			}
	
			// Save deviceList to local storage
			try! DeviceManager.Local.saveDeviceList(deviceList: updatedDeviceList)
	
			// Update widget views
			self.updateWidgetViews()
		}.catch { error in
			print("Error: \(error)")
		}
	}
	
    @IBAction func GiveComfortFeedback(_ sender: UIButton) {
        // Get the current device viewModel.
		guard let currentDevice = getCurrentDeviceViewModel()?.device else {
			print("Could not give comfort feedback, currentDeviceViewModel not found")
			return
		}
        
        var comfortLevel: ComfortLevel?
        if sender.tag == 1 {
            // Show loading indicator.
            bitWarmButton.loadingIndicator(show: true)
            comfortLevel = .BitWarm
        } else if sender.tag == 2 {
            // Show loading indicator.
            bitColdButton.loadingIndicator(show: true)
            comfortLevel = .BitCold
        }
        
        // Send comfort feedback to the API.
        DeviceManager.API.giveComfortFeedback(for: currentDevice, with: comfortLevel!).done { success in
            success ? print("Feedback given: \(comfortLevel!)") :
                print("Something went wrong while trying to give feedback \(comfortLevel!)")
            
            // Hide loading indicator.
            comfortLevel == .BitWarm ? self.bitWarmButton.loadingIndicator(show: false) : self.bitColdButton.loadingIndicator(show: false)
            
            }.catch { error in
                print("Error: \(error)")
        }
    }
    
    @IBAction func switchToComfortMode(_ sender: UIButton) {
		// Show loading indicator.
        self.comfortButton.loadingIndicator(show: true)
        
		guard let currentDevice = getCurrentDeviceViewModel()?.device else {
			print("Could not give comfort feedback, currentDeviceViewModel not found")
			return
		}
        
        // Send comfort mode instruction to the API.
        DeviceManager.API.comfortMode(for: currentDevice, with: SimpleMode.Comfort).done { success in
            success ? print("The device has been set to comfort mode.") :
                print("Failed to set the device to comfort mode.")
            
            // Hide loading indicator.
            self.comfortButton.loadingIndicator(show: false)
            }.catch { error in
                print("Error: \(error)")
        }
    }
    
    
    @IBAction func switchDeviceToOffMode(_ sender: UIButton) {
		// Show loading indicator.
        self.offButton.loadingIndicator(show: true)
        
		guard let currentDevice = getCurrentDeviceViewModel()?.device else {
			print("Could not give comfort feedback, currentDeviceViewModel not found")
			return
		}
        
        // Send power off instruction to the API.
        DeviceManager.API.powerOff(for: currentDevice).done { success in
            success ? print("The device has been set to off mode") : print("Failed to set device to off mode.")
            
            // Hide loading indicator.
            self.offButton.loadingIndicator(show: false)
            }.catch { error in
                print("Error: \(error)")
        }
    }
    
    @IBAction func touchSwitchDeviceButton(_ sender: UIButton) {
        var direction: SwitchDirection?
        
        if sender.tag == 6 {
            direction = .left
        } else if sender.tag == 7 {
            direction = .right
        }
        switchDevice(with: direction!)
    }
    
    func switchDevice(with direction: SwitchDirection) {
		let currentIndex = getCurrentDeviceViewModelIndex()
		var newIndex = currentIndex
		
		print("currentIndex: \(currentIndex)")
		
		// If no deviceViewModels exist, return nil
		if deviceViewModels == nil { return }
		if deviceViewModels!.count < 1 { return }
		
        switch direction {
		case .left:
			if currentIndex + 1 == deviceViewModels!.endIndex {
				newIndex = 0
			} else {
				newIndex += 1
			}
		case .right:
			if currentIndex - 1 < deviceViewModels!.startIndex {
				newIndex = deviceViewModels!.endIndex - 1
			} else {
				newIndex -= 1
			}
		}
		
		print("newIndex: \(newIndex)")
		
		// Update local devices
		var deviceList = try! DeviceManager.Local.getDeviceList()
		currentDeviceId = deviceList[newIndex].id
		try! DeviceManager.Local.saveDeviceList(deviceList: deviceList)
		
		// Update view (with local data)
        self.updateWidgetViews()
		
		// Update current shown device with new status data and update view again
		self.updateCurrentDevice()
    }
    
}

extension UIViewController {
    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
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

extension UIButton {
    func loadingIndicator(show: Bool) {
        if show {
            let indicator = UIActivityIndicatorView()
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            indicator.style = .whiteLarge
            self.addSubview(indicator)
            indicator.startAnimating()
            
            // Change background image.
            switch self.tag {
            case 1:
                self.setImage(UIImage(named: "icon-abitwarm-2-bg"), for: UIControl.State.normal)
            case 2:
                self.setImage(UIImage(named: "icon-abitcold-2-bg"), for: UIControl.State.normal)
            case 3:
                self.setImage(UIImage(named: "icon-comfort-bg"), for: UIControl.State.normal)
            case 4:
                self.setImage(UIImage(named: "icon-off-bg"), for: UIControl.State.normal)
            default:
                print("ERRR Something went wrong")
                return
            }
        } else {
            for view in self.subviews {
                if let indicator = view as? UIActivityIndicatorView {
                    indicator.stopAnimating()
                    indicator.removeFromSuperview()
                    
                    // Change background image.
                    switch self.tag {
                    case 1:
                        self.setImage(UIImage(named: "icon-abitwarm-2"), for: UIControl.State.normal)
                    case 2:
                        self.setImage(UIImage(named: "icon-abitcold-2"), for: UIControl.State.normal)
                    case 3:
                        self.setImage(UIImage(named: "icon-comfort"), for: UIControl.State.normal)
                    case 4:
                        self.setImage(UIImage(named: "icon-off"), for: UIControl.State.normal)
                    default:
                        print("ERRR Something went wrong")
                        return
                    }
                }
            }
        }
    }
}
