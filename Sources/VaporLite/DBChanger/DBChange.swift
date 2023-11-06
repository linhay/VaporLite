//
//  File.swift
//  
//
//  Created by linhey on 2023/5/30.
//

import Foundation
import FluentKit
import STJSON

public class DBChange<Table: DBChangable>: DBChanger {
    
    public var database: Database
    public var table_store: (() async throws -> Table)?
    
    public init(on database: Database) {
        self.database = database
    }
    
}

public extension DBChange {
 
    func scope<Value>(_ keyPath: ReferenceWritableKeyPath<Table, Value>) -> DBPathChange<Table, Value> {
        .init(keyPath: keyPath, on: database)
    }
    
}

public extension DBChange {
    
    func delete() async throws {
        try await self.table().delete(on: database)
    }
    
    func save() async throws {
        try await self.table().save(on: database)
    }
    
    func task(_ change: (_ table: Table) async throws -> Void) async throws {
        try await buildTask({ table in
            try await change(table)
            return table
        })
    }
    
    func buildTask(_ change: (_ table: Table) async throws -> Table) async throws {
        var table = try await self.table()
        table = (try? await change(table)) ?? table
        try await table.save(on: database)
    }
    
}

public extension DBChange {
    
    func get<V>(_ block: (_ table: Table) async throws -> V) async throws -> V {
        try await block(self.table())
    }
    
    func get<V>(_ path: KeyPath<Table, V>) async throws -> V {
        try await get { table in
            table[keyPath: path]
        }
    }
    
    func set<V>(for path: ReferenceWritableKeyPath<Table, V>, _ value: V) async throws {
       try await buildTask { table in
           let table = table
           table[keyPath: path] = value
           return table
        }
    }
    
}

public extension DBChange {
    
    func setJSON<V: Encodable>(for path: ReferenceWritableKeyPath<Table, String?>, _ value: V) async throws {
        try await task { table in
            try table.setJSON(for: path, value)
        }
    }
    
    func getJSON<V: Decodable>(_ type: V.Type, from path: KeyPath<Table, String?>) async throws -> V {
        try await get { table in
            try table.getJSON(type, from: path)
        }
    }
    
    func setJSON<V: Encodable>(for path: ReferenceWritableKeyPath<Table, String>, _ value: V) async throws {
        try await task { table in
            try table.setJSON(for: path, value)
        }
    }
    
    func getJSON<V: Decodable>(_ type: V.Type, from path: KeyPath<Table, String>) async throws -> V {
        try await get { table in
            try table.getJSON(type, from: path)
        }
    }
    
}
