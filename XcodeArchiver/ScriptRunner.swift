//
//  ScriptRunner.swift
//  XcodeArchiver
//
//  Created by 刁世浩 on 2020/6/3.
//  Copyright © 2020 刁世浩. All rights reserved.
//

import Foundation

//==============================================================
//MARK: Base Script Runner Protocol
//==============================================================

typealias TerminationHandler = (Process) -> Void
typealias OutputHandler = (_ data: Data, _ text: String, _ json: [String: Any]?) -> Void

protocol ScriptRunner {
    var launchPath: String { get }
}

extension ScriptRunner {
    
    @discardableResult
    func runTask(arguments: [String], outputHandler: OutputHandler?, terminationHandler: TerminationHandler?) -> Process {
        let task = Process()
        DispatchQueue.global(qos: .background).async {
            task.arguments = arguments
            task.launchPath = self.launchPath
            task.terminationHandler = terminationHandler
            self.captureStandardOutput(task: task, handler: outputHandler)
            task.launch()
            task.waitUntilExit()
        }
        return task
    }
    
    func captureStandardOutput(task: Process, handler: OutputHandler?) {
        let outputPipe = Pipe()
        task.standardError = outputPipe
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) { notification in
            let output = outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            if output.count > 0 {
                handler?(output, outputString, try? JSONSerialization.jsonObject(with: output, options: .allowFragments) as? [String : Any])
            }
            outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
}

//==============================================================
//MARK: Xcode Build Script Protocol
//==============================================================

enum ProjectType: String {
    case xcodeproj
    case xcworkspace
    
    var string: String {
        switch self {
        case .xcodeproj: return "project"
        case .xcworkspace: return "workspace"
        }
    }
    var hyphenString: String {
        switch self {
        case .xcodeproj: return "-project"
        case .xcworkspace: return "-workspace"
        }
    }
}

struct ArchiveItem {
    var type: ProjectType
    var schemeName: String
    var projectPath: String
    var archiveLocation: String
    
    var archivePath: String {
        archiveLocation + "/Archived/" + schemeName + ".xcarchive"
    }
    var exportPath: String {
        archiveLocation + "/Exported/"
    }
}

protocol XcodeBuildScript: ScriptRunner {
    var exportOptionsPath: String? { get }
    var exportMethod: ExportMethod? { get }
}

extension XcodeBuildScript {
    var launchPath: String { "/usr/bin/xcodebuild" }
    var exportOptionsPath: String? {
        exportMethod?.exportOptionsPath
    }
}

extension XcodeBuildScript {
    func loadSchemes(type: ProjectType, projectPath path: String, complete: (([String]) -> Void)?) {
        runTask(arguments: ["-list", type.hyphenString, path, "-json"], outputHandler: { (_, text, json) in
            if let project = json?[type.string] as? [String: Any], let schemes = project["schemes"] as? [String] {
                complete?(schemes)
            }
        }, terminationHandler: nil)
    }
    
    func cleanItem(_ item: ArchiveItem, outputHandler: OutputHandler?, terminationHandler: TerminationHandler?) {
        runTask(arguments: ["clean", item.type.hyphenString, item.projectPath, "-scheme", item.schemeName], outputHandler: outputHandler, terminationHandler: terminationHandler)
    }
    
    func archiveItem(_ item: ArchiveItem, outputHandler: OutputHandler?, terminationHandler: TerminationHandler?) -> Process {
        return runTask(arguments: ["archive", item.type.hyphenString, item.projectPath, "-scheme", item.schemeName, "-archivePath", item.archivePath], outputHandler: outputHandler, terminationHandler: terminationHandler)
    }
    
    func exportItem(_ item: ArchiveItem, outputHandler: OutputHandler?, terminationHandler: TerminationHandler?) -> Process {
        return runTask(arguments: ["-exportArchive", "-archivePath", item.archivePath, "-exportPath", item.exportPath, "-exportOptionsPlist", exportOptionsPath ?? ""], outputHandler: outputHandler, terminationHandler: terminationHandler)
    }
}
