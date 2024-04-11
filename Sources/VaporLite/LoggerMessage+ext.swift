//
//  File.swift
//
//
//  Created by linhey on 2024/1/25.
//

import Logging
import STJSON
import Foundation

public enum LoggerMessagePayloadStatus: String, Codable {
    // 表示正在加载或处理
    case loading = "🕐"
    // 表示失败
    case failure = "❌"
    // 表示成功
    case success = "✅"
}

public final class LoggerMessageTrack: Codable, ExpressibleByStringLiteral {
    
    public var id: String?
    public var name: String?
    public var status: LoggerMessagePayloadStatus?
    
    public init(name: String?, id: String? = nil, status: LoggerMessagePayloadStatus? = nil) {
        if let id = id, !id.isEmpty {
            self.id = id
        } else {
            self.id = nil
        }
        self.name = name
        self.status = status
    }
    
    public convenience init(stringLiteral value: String) {
        self.init(name: value)
    }
    
}

public struct LoggerMessagePayload<Element: Codable>: Codable {
    
    public var _track: LoggerMessageTrack?
    public var data: Element?
    
    public init(track: LoggerMessageTrack) where Element == Int {
        self._track = track
        self.data = nil
    }
    
    public init(track: LoggerMessageTrack? = nil, data: Element) {
        self._track = track
        self.data = data
    }
    
    
}

public extension Logger.Message {
    
    init<Element: Codable>(payload: LoggerMessagePayload<Element>) {
        self.init(codable: payload)
    }
    
    init(track: LoggerMessageTrack) {
        self.init(payload: .init(track: track))
    }
    
    init(track: String, status: LoggerMessagePayloadStatus) {
        self.init(payload: .init(track: .init(name: track, status: status)))
    }
    
    init<Element: Codable>(codable payload: Element) {
        let str = try? JSONEncoder.encodeToJSON(payload, builder: { encoder in
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        })
        self.init(stringLiteral: str ?? "")
    }
    
}
