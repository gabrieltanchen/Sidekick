//
//  AppDelegate.swift
//  Sidekick_iOS
//
//  Created by Gabriel Tan-Chen on 2015-02-19.
//  Copyright (c) 2015 Gabriel Tan-Chen. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window:UIWindow?
    var mainViewController:BLEMainViewController?
    
    required override init() {
        super.init()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        // Load NIB based on current platform
        var nibName:String
        if IS_IPHONE {
            nibName = "BLEMainViewController_iPhone"
        }
        else{
            nibName = "BLEMainViewController_iPad"
        }
        self.mainViewController = BLEMainViewController(nibName: nibName, bundle: NSBundle.mainBundle())    //TODO: check for redundancy
        
        window!.rootViewController = mainViewController
        window!.makeKeyAndVisible()
        
        // Ask user for permision to show local notifications
        if(UIApplication.instancesRespondToSelector(Selector("registerUserNotificationSettings:")))
        {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert | UIUserNotificationType.Badge, categories: nil))
        }
        else
        {
            //do iOS 7 stuff, which is pretty much nothing for local notifications.
        }
        
        return true
        
    }
    
    func applicationWillResignActive(application: UIApplication) {
        
        // Stop scanning before entering background
        mainViewController?.stopScan()
        
        //TEST NOTIFICATION
        //        let note = UILocalNotification()
        //        note.fireDate = NSDate().dateByAddingTimeInterval(5.0)
        //        note.alertBody = "THIS IS A TEST"
        //        note.soundName =  UILocalNotificationDefaultSoundName
        //        application.scheduleLocalNotification(note)
        
    }
    
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        mainViewController?.didBecomeActive()
    }
}

