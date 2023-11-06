//
//  File.swift
//
//
//  Created by linhey on 2023/7/10.
//

import Foundation
import FluentKit
import STJSON

public protocol DBChangable: Model {
    
    init(id: IDValue?) throws
    
}

public extension DBChangable {
    
    static func changer(on database: Database) -> DBChange<Self> {
        .init(on: database)
    }
    
    static func changer<Value>(keyPath: ReferenceWritableKeyPath<Self, Value>, on database: Database) -> DBPathChange<Self, Value> {
        .init(keyPath: keyPath, on: database)
    }
    
}

public extension DBChangable {
    
    func set<V>(for path: ReferenceWritableKeyPath<Self, V>, _ value: V) throws {
        self[keyPath: path] = value
    }
    
    func get<V>(for path: KeyPath<Self, V>) throws -> V {
        self[keyPath: path]
    }
}

public extension DBChangable {
    
    func setJSON<V: Encodable>(for path: ReferenceWritableKeyPath<Self, String?>, _ value: V) throws {
        let data = try JSONEncoder.shared.encode(value)
        guard let str = String(data: data, encoding: .utf8) else {
            throw AxLiteError.db_encode
        }
        self[keyPath: path] = str
    }
    
    func getJSON<V: Decodable>(_ type: V.Type, from path: KeyPath<Self, String?>) throws -> V {
        guard let data = self[keyPath: path]?.data(using: .utf8) else {
            throw AxLiteError.db_decode
        }
        return try JSONDecoder.shared.decode(V.self, from: data)
    }
    
    func setJSON<V: Encodable>(for path: ReferenceWritableKeyPath<Self, String>, _ value: V) throws {
        let data = try JSONEncoder.shared.encode(value)
        guard let str = String(data: data, encoding: .utf8) else {
            throw AxLiteError.db_encode
        }
        self[keyPath: path] = str
    }
    
    func getJSON<V: Decodable>(_ type: V.Type, from path: KeyPath<Self, String>) throws -> V {
        guard let data = self[keyPath: path].data(using: .utf8) else {
            throw AxLiteError.db_decode
        }
        return try JSONDecoder.shared.decode(V.self, from: data)
    }
    
}

public extension DBChangable {
    
    static func scan(page_size: Int = 1000,
                     on database: Database,
                     callback: ((DBChange<Self>) async throws -> Void),
                     finish: (() async throws -> Void)? = nil) async throws {
        let count = try await Self.query(on: database).count()
        let max_page_number = count / page_size + (count % page_size == 0 ? 0 : 1)
        for index in 1...max_page_number {
            let items = try await Self
                .query(on: database)
                .page(withIndex: index, size: page_size)
                .items
            for item in items {
                try await callback(Self.changer(on: database).table(item))
            }
        }
        try await finish?()
    }
    
}
