//
//  File.swift
//  
//
//  Created by linhey on 2024/1/26.
//

import Foundation
import Fluent
import STJSON

public extension Model {
    
    func decode<V: Decodable>(_ path: ReferenceWritableKeyPath<Self, String?>, _ type: V.Type) throws -> V {
        guard let data = self[keyPath: path]?.data(using: .utf8) else {
            throw AxError.database_decode
        }
        return try JSONDecoder.shared.decode(type, from: data)
    }
    
    func decode<V: JSONDecodableModel>(_ path: ReferenceWritableKeyPath<Self, String?>, _ type: V.Type) throws -> V {
        guard let str = self[keyPath: path] else {
            throw AxError.database_decode
        }
        return try .init(from: JSON(parseJSON: str))
    }
    
    func json(_ path: ReferenceWritableKeyPath<Self, String?>, _ value: JSON) -> Self {
        self[keyPath: path] = value.rawString()
        return self
    }
    
    func json(_ path: ReferenceWritableKeyPath<Self, String?>, _ value: Codable) -> Self {
        guard let data = try? JSONEncoder.shared.encode(value), let string = String(data: data, encoding: .utf8) else {
                return self
            }
        self[keyPath: path] = string
        return self
    }
    
    func json(_ path: KeyPath<Self, String?>) -> JSON? {
        guard let value = self[keyPath: path]?.data(using: .utf8) else {
            return nil
        }
        return try? .init(data: value)
    }
    
    func json(_ path: KeyPath<Self, String>) -> JSON? {
        guard let value = self[keyPath: path].data(using: .utf8) else {
            return nil
        }
        return try? .init(data: value)
    }
    
    static func scan(page_size: Int = 1000,
                     on database: Database,
                     callback: ((_ model: Self) async throws -> Void),
                     finish: (() async throws -> Void)? = nil) async throws {
        let count = try await Self.query(on: database).count()
        guard count > 0 else {
            return
        }
        let max_page_number = count / page_size + (count % page_size == 0 ? 0 : 1)
        for index in 1...max_page_number {
            let items = try await Self
                .query(on: database)
                .page(withIndex: index, size: page_size)
                .items
            for item in items {
                try await callback(item)
            }
        }
        try await finish?()
    }

    
}
