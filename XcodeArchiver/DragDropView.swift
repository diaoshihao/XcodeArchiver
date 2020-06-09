//
//  DragDropView.swift
//  XcodeArchiver
//
//  Created by 刁世浩 on 2020/6/8.
//  Copyright © 2020 刁世浩. All rights reserved.
//

import Cocoa

class DragDropView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        registerForDraggedTypes([.fileURL])
    }
    
    deinit {
        unregisterDraggedTypes()
    }
}

extension DragDropView {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let types = sender.draggingPasteboard.types, types.contains(.fileURL) {
            return .copy
        }
        return .generic
    }
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print(sender)
        guard let pasteboardItems = sender.draggingPasteboard.pasteboardItems, pasteboardItems.count > 0 else { return false }
        if pasteboardItems.count == 1 {
            return true
        }
        return false
    }
}
