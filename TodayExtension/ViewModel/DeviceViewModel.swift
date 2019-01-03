//
//  DeviceViewModel.swift
//  TodayExtension
//
//  Created by Milan Sosef on 3/12/2018.
//  Copyright © 2018 tonglaicha. All rights reserved.
//

import Foundation
import UIKit

class DeviceViewModel {
    public let device: Device
    
    init(device: Device) {
        self.device = device
    }
    
    public var deviceTitleText: String {
        return device.name
    }
    
    public var locationNameText: String {
        guard let value = device.locationName else {
            return "-"
        }
        
        return value
    }
    
    public var temperatureLabel: String {
		guard var value = device.temperature else {
			return "‒"
		}
		value = round(value * 10) / 10
		
		// Do fahrenheit / celsius conversions here.
		
		return "\(value)°"
    }
    
    public var humidityLabel: String {
		guard var value = device.humidity else {
			return "‒"
		}
		value = round(value * 10) / 10
		print("Humidity: \(value)")
		return "\(value)%"
    }
    
    public var modeIcon: UIImage {
		
		guard let simpleMode = device.simpleMode else {
			return UIImage(named: "icn_mode_off_grey")!
		}
		
        switch simpleMode {
        case .Comfort:
            return UIImage(named: "icn_mode_comfort")!
        case .Temperature:
            return UIImage(named: "icn_mode_temperature")!
        case .Manual:
            return UIImage(named: "icn_mode_manual")!
        case .Off:
            return UIImage(named: "icn_mode_off_grey")!
        }
    }
}
