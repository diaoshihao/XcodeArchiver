/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Cocoa

class TasksViewController: NSViewController {
    
    //Controller Outlets
    @IBOutlet var outputText:NSTextView!
    @IBOutlet var spinner:NSProgressIndicator!
    
    @IBOutlet weak var objectPathControl:NSPathControl!
    @IBOutlet weak var savePathControl: NSPathControl!
    @IBOutlet weak var schemeNameButton: NSPopUpButton!
    
    @IBOutlet weak var archiveButton: NSButton!
    @IBOutlet weak var exportButton: NSButton!
    
    var currentTask:Process?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadHistoryItem()
    }
}

//==============================================================
//MARK: Task Actions
//==============================================================

extension TasksViewController {
    @IBAction func listInfo(_ sender: NSPathCell) {
        guard let path = sender.url?.path, let fileName = path.components(separatedBy: "/").last else {
            setText("请选择打包对象")
            return
        }
        
        let projectType = ProjectType(rawValue: fileName.components(separatedBy: ".").last ?? "")
        guard let type = projectType else {
            setText("请选择正确的打包文件类型")
            return
        }
        
        setText("正在加载 schemes...")
        loadSchemes(type: type, projectPath: path) { (schemes) in
            self.setText("schemes 已加载，请选择")
            self.didLoadSchemes(schemes)
        }
    }
    
    @IBAction func archiveAction(_ sender: Any) {
        guard let item = validateArchiveItem() else {
            return
        }
        setText("")
        didBeginArchive()
        cacheHistory(with: item)
        if !preferences.cleanFirst {
            beginArchiveItem(with: item) { (task) in
                self.didFinishTask()
            }
            return
        }
        
        beginCleanItem(with: item) { (task) in
            self.beginArchiveItem(with: item) { (task) in
                self.didFinishTask()
            }
        }
    }
    
    @IBAction func archive_exportAction(_ sender: Any) {
        guard let item = validateArchiveItem() else {
            return
        }
        setText("")
        didBeginArchive()
        cacheHistory(with: item)
        if !preferences.cleanFirst {
            beginArchiveItem(with: item) { (task) in
                if task.terminationStatus == 0 {
                    self.beginExportItem(with: item) { (_) in
                        self.didFinishTask()
                    }
                }
            }
            return
        }
        
        beginCleanItem(with: item) { (task) in
            self.beginArchiveItem(with: item) { (task) in
                if task.terminationStatus == 0 {
                    self.beginExportItem(with: item) { (_) in
                        self.didFinishTask()
                    }
                }
            }
        }
    }
    
    @IBAction func stopTask(_ sender:AnyObject) {
        if let task = currentTask, task.isRunning {
            currentTask?.terminate()
            self.appendText("用户取消任务")
        }
        didFinishTask()
    }
}

//==============================================================
//MARK: Xcode Build Script
//==============================================================

extension TasksViewController: XcodeBuildScript {
    var exportMethod: ExportMethod? {
        .development
    }
    
    func beginCleanItem(with item: ArchiveItem, terminationHandler: TerminationHandler?) {
        setText("开始清理 Build 文件夹")
        cleanItem(item, outputHandler: { (_, text, _) in
            self.appendText(text)
        }, terminationHandler: terminationHandler)
    }
    
    func beginArchiveItem(with item: ArchiveItem, terminationHandler: TerminationHandler?) {
        self.appendText("开始执行打包...")
        self.currentTask = self.archiveItem(item, outputHandler: { (_, text, _) in
            self.appendText(text)
        }) { (task) in
            if task.terminationStatus == 0 {
                self.appendText("打包已完成，包文件路径：\(item.archivePath)")
            } else {
                self.appendText("打包失败")
                self.didFinishTask()
            }
            terminationHandler?(task)
        }
    }
    
    func beginExportItem(with item: ArchiveItem, terminationHandler: TerminationHandler?) {
        appendText("开始执行导出...")
        currentTask = exportItem(item, outputHandler: { (_, text, _) in
            self.appendText(text)
        }) { (task) in
            if task.terminationStatus == 0 {
                self.appendText("导出已完成，导出文件路径：\(item.exportPath)")
            } else {
                self.appendText("导出失败")
            }
            terminationHandler?(task)
        }
    }
    
    func validateArchiveItem() -> ArchiveItem? {
        guard let path = objectPathControl.url?.path, let fileName = path.components(separatedBy: "/").last else {
            setText("请选择打包对象")
            return nil
        }
        
        guard let archiveLocation = savePathControl.url?.path else {
            setText("请选择存储位置")
            return nil
        }
        
        guard let schemeName = schemeNameButton.selectedItem?.title else {
            setText("请选择 scheme")
            return nil
        }
        
        let projectType = ProjectType(rawValue: fileName.components(separatedBy: ".").last ?? "")
        guard let type = projectType else {
            setText("请选择正确的打包文件类型")
            return nil
        }
        
        return ArchiveItem(type: type, schemeName: schemeName, projectPath: path, archiveLocation: archiveLocation)
    }
}

//==============================================================
//MARK: UI Refresh
//==============================================================

extension TasksViewController {
    
    func didLoadSchemes(_ schemes:[String]) {
        DispatchQueue.main.async {
            self.schemeNameButton.removeAllItems()
            self.schemeNameButton.addItems(withTitles: schemes)
        }
    }
    
    func didBeginArchive() {
        DispatchQueue.main.async {
            self.archiveButton.isEnabled = false
            self.exportButton.isEnabled = false
            self.spinner.startAnimation(self)
        }
    }
    
    func didFinishTask() {
        DispatchQueue.main.async {
            self.archiveButton.isEnabled = true
            self.exportButton.isEnabled = true
            self.spinner.stopAnimation(self)
        }
    }
    
    func setText(_ text: String) {
        DispatchQueue.main.async {
            self.outputText.string = text
        }
    }
    
    func appendText(_ text: String) {
        DispatchQueue.main.async {
            let preText = self.outputText.string
            let currentText = preText + "\n" + text
            self.outputText.string = currentText
            let range = NSRange(location:currentText.count, length:0)
            self.outputText.scrollRangeToVisible(range)
        }
    }
}

//==============================================================
//MARK: History Cache
//==============================================================

extension TasksViewController {
    
    func loadHistoryItem() {
        schemeNameButton.removeAllItems()
        
        guard let historyItem = history.first else {
            schemeNameButton.addItem(withTitle: "请选择打包对象")
            return
        }
        
        schemeNameButton.addItems(withTitles: historyItem.schemes)
        schemeNameButton.selectItem(withTitle: historyItem.selectedScheme)
        objectPathControl.url = URL(fileURLWithPath: historyItem.projectPath)
        savePathControl.url = URL(fileURLWithPath: historyItem.archiveLocation, isDirectory: true)
    }
    
    func cacheHistory(with item: ArchiveItem) {
        let history = ArchiveHistory(projectPath: item.projectPath, archiveLocation: item.archiveLocation, schemes: schemeNameButton.itemTitles, selectedScheme: schemeNameButton.title)
        history.writeToCache()
    }
}
