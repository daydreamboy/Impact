//
//  AppDelegate.swift
//  ImpactTestiOS
//
//  Created by Matt Massicotte on 2020-06-24.
//  Copyright © 2020 Chime Systems Inc. All rights reserved.
//

import UIKit
import Impact

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let backupPath = NSTemporaryDirectory().appendingFormat("/%f.txt", Date.init().timeIntervalSince1970);
        let path = backupPath;
        let url = URL(fileURLWithPath: path, isDirectory: false)

        ImpactMonitor.shared.suppressReportCrash = UserDefaults.standard.bool(forKey: "suppressReportCrash")
        ImpactMonitor.shared.start(with: url, identifier: UUID())

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

