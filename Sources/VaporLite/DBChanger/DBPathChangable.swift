//
//  File.swift
//  
//
//  Created by linhey on 2023/7/10.
//

import Foundation
import FluentKit
import STJSON

public class DBPathChange<Table: DBChangable, Value>: DBChanger {
   
    public var table_store: (() async throws -> Table)?
    public let keyPath: ReferenceWritableKeyPath<Table, Value>
    public var database: Database
    
    public init(keyPath: ReferenceWritableKeyPath<Table, Value>,
         on database: Database) {
        self.keyPath = keyPath
        self.database = database
    }
    
}

public extension DBPathChange {
    
    func get() async throws -> Value {
        let table = try await self.table()
        return table[keyPath: keyPath]
    }
    
    func set(_ value: Value) async throws {
        let table = try await self.table()
        table[keyPath: keyPath] = value
        try await table.save(on: database)
    }
    
}

public extension DBPathChange where Value == String {
    
    func setJSON<V: Encodable>(_ value: V) async throws {
        let table = try await self.table()
        try table.setJSON(for: keyPath, value)
        try await table.save(on: database)
    }
    
    func getJSON<V: Decodable>(_ type: V.Type) async throws -> V {
        try await self.table().getJSON(type, from: keyPath)
    }
    
}

public extension DBPathChange where Value == String? {
    
    func setJSON<V: Encodable>(_ value: V) async throws {
        let table = try await self.table()
        try table.setJSON(for: keyPath, value)
        try await table.save(on: database)
    }
    
    func getJSON<V: Decodable>(_ type: V.Type) async throws -> V {
        try await self.table().getJSON(type, from: keyPath)
    }
    
}
