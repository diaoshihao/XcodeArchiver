//
//  ArchiveHistory.swift
//  XcodeArchiver
//
//  Created by 刁世浩 on 2020/6/9.
//  Copyright © 2020 刁世浩. All rights reserved.
//

import Foundation

var history: [ArchiveHistory] =  fetchHistoryPlist()

struct ArchiveHistory {
    var projectPath: String
    var archiveLocation: String
    var schemes: [String]
    var selectedScheme: String
    
    static var path: String {
        HistoryDirectory + "/history.plist"
    }
}

extension ArchiveHistory {
    func writeToCache() {
        if !FileManager.default.fileExists(atPath: ArchiveHistory.path) {
            createDirectoryIfNeed(atPath: HistoryDirectory)
        }
        history.removeAll(where: { $0.projectPath == projectPath })
        history.insert(self, at: 0)
        let array = history.map({ $0.convertToDictionary() }) as NSArray
        array.write(toFile: ArchiveHistory.path, atomically: true)
    }
    
    func convertToDictionary() -> [String: Any] {
        return ["projectPath": projectPath, "archiveLocation": archiveLocation, "selectedScheme": selectedScheme, "schemes": schemes]
    }
    
    static func convertToHistory(from dict: [String: Any]) -> ArchiveHistory? {
        guard let projectPath = dict["projectPath"] as? String else { return nil }
        guard let archiveLocation = dict["archiveLocation"] as? String else { return nil }
        guard let selectedScheme = dict["selectedScheme"] as? String else { return nil }
        guard let schemes = dict["schemes"] as? [String] else { return nil }
        return ArchiveHistory(projectPath: projectPath, archiveLocation: archiveLocation, schemes: schemes, selectedScheme: selectedScheme)
    }
}

func fetchHistoryPlist() -> [ArchiveHistory] {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: ArchiveHistory.path)) else {
        return []
    }
    
    guard let array = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: .none) as? [[String: Any]] else {
        return []
    }
    
    return array.compactMap({ ArchiveHistory.convertToHistory(from: $0) })
}
