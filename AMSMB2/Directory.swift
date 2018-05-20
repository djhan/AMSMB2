//
//  Directory.swift
//  AMSMB2
//
//  Created by Amir Abbas Mousavian.
//  Copyright © 2018 Mousavian. Distributed under MIT license.
//

import Foundation
import SMB2
typealias smb2dir = OpaquePointer

/// NO THREAD-SAFE
class SMB2Directory: Collection {
    
    typealias Index = Int
    
    fileprivate var context: SMB2Context
    fileprivate var handle: smb2dir
    
    init(_ path: String, on context: SMB2Context) throws {
        guard let handle = smb2_opendir(context.context, path) else {
            throw POSIXError(.EBADF)
        }
        self.context = context
        self.handle = handle
    }
    
    deinit {
        smb2_closedir(context.context, handle)
    }
    
    struct Iterator: IteratorProtocol {
        var object: SMB2Directory
        typealias Element = smb2dirent
        
        mutating func next() -> SMB2Directory.Iterator.Element? {
            return smb2_readdir(object.context.context, object.handle)?.move()
        }
    }
    
    func makeIterator() -> SMB2Directory.Iterator {
        smb2_rewinddir(context.context, handle)
        return Iterator(object: self)
    }
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        var i = 0
        let currentPos = smb2_telldir(context.context, handle)
        smb2_rewinddir(context.context, handle)
        defer {
            smb2_seekdir(context.context, handle, currentPos)
        }
        
        while smb2_readdir(context.context, handle) != nil {
            i += 1
        }
        return i
    }
    
    subscript(position: Int) -> smb2dirent {
        let currentPos = smb2_telldir(context.context, handle)
        smb2_seekdir(context.context, handle, 0)
        defer {
            smb2_seekdir(context.context, handle, currentPos)
        }
        return smb2_readdir(context.context, handle).move()
    }
    
    func index(after i: Int) -> Int {
        return i + 1
    }
}