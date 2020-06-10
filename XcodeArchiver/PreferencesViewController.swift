//
//  PreferencesViewController.swift
//  XcodeArchiver
//
//  Created by 刁世浩 on 2020/6/3.
//  Copyright © 2020 刁世浩. All rights reserved.
//

import Cocoa

struct Preferences {
    var cleanFirst: Bool = true
    var rememberLast: Bool = true
}

var preferences = Preferences()

class PreferencesViewController: NSViewController {

    
    @IBAction func rememberLastAction(_ sender: NSButton) {
    }
    
    @IBAction func cleanFirstAciont(_ sender: NSButton) {
        preferences.cleanFirst = sender.state == .on
    }
}
