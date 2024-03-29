//
//  AppDelegate.swift
//  AmbiWidget-IOS
//
//  Created by Brandon Yuen & Milan Sosef
//  Copyright © 2018 tonglaicha. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
	
	func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
		
		// Determine who sent the URL.
		let sendingAppID = options[.sourceApplication]
		print("source application = \(sendingAppID ?? "Unknown")")
		
		// Check if url is correct
		guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true), let params = components.queryItems else {
				print("Invalid URL or album path missing")
				return false
		}
		
		// Get authCode from query params
		guard let authCode = params.first(where: { $0.name == "code" })?.value else {
			print("[\(String(describing: self))] Could not retrieve authCode when opening app from browser URL.")
			return false
		}
		
		NotificationCenter.default.post(name: .onAuthCodeReceive, object: self, userInfo: ["authCode": authCode])
		
		return true
	}

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		SettingsBundleHelper.checkAndExecuteSettings()
		SettingsBundleHelper.setVersionAndBuildNumber()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

