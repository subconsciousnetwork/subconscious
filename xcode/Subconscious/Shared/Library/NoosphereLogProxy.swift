//
//  NoosphereLogProxy.swift
//  Subconscious
//
//  Created by Ben Follington on 20/12/2023.
//

import Foundation
import os
import OSLog

public enum NoosphereLogProxy {}

extension NoosphereLogProxy {
    public static let pipe = Pipe()
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "StdOut"
    )
    
    /// Redirect STDOUT to a logger to capture it in production
    public static func connect() -> Void {
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            let str = String(
                data: data,
                encoding: .ascii
            ) ?? "<Non-ascii data of size\(data.count)>\n"
            DispatchQueue.main.async {
                logger.log("\(str, privacy: .public)")
            }
        }
    }
}

