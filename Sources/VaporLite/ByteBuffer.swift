//
//  File.swift
//  
//
//  Created by linhey on 2023/7/14.
//

import Vapor

public extension ByteBuffer {
    
    var string: String? {
        get throws {
            if let message = String(data: Data(readableBytesView), encoding: .utf8) {
               return message
            } else {
                return nil
            }
        }
    }
    
}
