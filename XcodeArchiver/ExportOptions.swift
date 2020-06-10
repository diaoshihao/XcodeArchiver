//
//  ExportOptions.swift
//  XcodeArchiver
//
//  Created by 刁世浩 on 2020/6/9.
//  Copyright © 2020 刁世浩. All rights reserved.
//

import Foundation

enum ExportMethod: String {
    case ad_hoc = "ad-hoc"
    case app_store = "app-store"
    case enterprise = "enterprise"
    case development = "development"
    
    var exportOptionsPath: String {
        switch self {
        case .ad_hoc: return ExportOptions.ad_hoc.path
        case .app_store: return ExportOptions.app_store.path
        case .enterprise: return ExportOptions.enterprise.path
        case .development: return ExportOptions.development.path
        }
    }
}

struct ExportOptions {
    var method: String
    var compileBitcode: Bool = true
    var stripSwiftSymbols: Bool = true
    var destination: String = "export"
    var signingStyle: String = "automatic"
    
    var path: String {
        ExportOptionsDirectory + "/" + method + ".plist"
    }
}

extension ExportOptions {
    static let ad_hoc = ExportOptions(method: ExportMethod.ad_hoc.rawValue)
    static let app_store = ExportOptions(method: ExportMethod.app_store.rawValue)
    static let enterprise = ExportOptions(method: ExportMethod.enterprise.rawValue)
    static let development = ExportOptions(method: ExportMethod.development.rawValue)
}

extension ExportOptions {
    func saveOptions() {
        let options = ["method": method, "compileBitcode": compileBitcode, "stripSwiftSymbols": stripSwiftSymbols, "signingStyle": signingStyle, "destination": destination] as NSDictionary
        guard let optionsPList = try? PropertyListSerialization.data(fromPropertyList: options, format: .xml, options: .zero) else {
            return
        }
        do {
            try optionsPList.write(to: URL(fileURLWithPath: path))
        } catch(let error) {
            print("保存文件失败: \(error)")
        }
    }
}
