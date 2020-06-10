//
//  AppDelegate.swift
//  XcodeArchiver
//
//  Created by 刁世浩 on 2020/6/1.
//  Copyright © 2020 刁世浩. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        createDirectoryIfNeed(atPath: ExportOptionsDirectory)
        createExportOptionsPlistIfNeed()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
