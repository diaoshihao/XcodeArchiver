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
        schemeNameButton.removeAllItems()
        schemeNameButton.addItem(withTitle: "请选择打包对象")
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
        didBeginArchive()
        beginArchiveItem(with: item) { (task) in
            self.didFinishTask()
        }
    }
    
    @IBAction func archive_exportAction(_ sender: Any) {
        guard let item = validateArchiveItem() else {
            return
        }
        didBeginArchive()
        beginArchiveItem(with: item) { (task) in
            if task.terminationStatus == 0 {
                self.beginExportItem(with: item) { (_) in
                    self.didFinishTask()
                }
            }
        }
    }
    
    @IBAction func stopTask(_ sender:AnyObject) {
        if let task = currentTask, task.isRunning {
            currentTask?.interrupt()
            self.appendText("已停止运行")
        }
        didFinishTask()
    }
}

//==============================================================
//MARK: Xcode Build Script
//==============================================================

extension TasksViewController: XcodeBuildScript {
    
    func beginArchiveItem(with item: ArchiveItem, terminationHandler: TerminationHandler?) {
        setText("开始执行打包...")
        currentTask = archiveItem(item, outputHandler: { (_, text, _) in
            self.appendText(text)
        }) { (task) in
            if task.terminationStatus == 0 {
                self.appendText("打包已完成，包文件路径：\(item.archivePath)")
            } else {
                switch task.terminationReason {
                case .exit: self.appendText("打包失败：用户停止")
                case .uncaughtSignal: self.appendText("打包失败：出现错误")
                default: self.appendText("打包失败")
                }
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
                switch task.terminationReason {
                case .exit: self.appendText("导出失败：用户停止")
                case .uncaughtSignal: self.appendText("导出失败：出现错误")
                default: self.appendText("导出失败")
                }
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
            self.outputText.string = self.outputText.string + "\n" + text
            let range = NSRange(location:self.outputText.string.count, length:0)
            self.outputText.scrollRangeToVisible(range)
        }
    }
}

//==============================================================
//MARK: History Cache
//==============================================================

extension TasksViewController {
    
}
