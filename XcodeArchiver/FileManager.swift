//
//  FileManager.swift
//  XcodeArchiver
//
//  Created by 刁世浩 on 2020/6/10.
//  Copyright © 2020 刁世浩. All rights reserved.
//

import Foundation

func createDirectoryIfNeed(atPath: String) {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: atPath) {
        try? fileManager.createDirectory(atPath: atPath, withIntermediateDirectories: true, attributes: nil)
    }
}

func createExportOptionsPlistIfNeed() {
    let fileManager = FileManager.default
    let options: [ExportOptions] = [.ad_hoc, .app_store, .enterprise, .development]
    options.forEach { (option) in
        if !fileManager.fileExists(atPath: option.path) {
            option.saveOptions()
        }
    }
}
