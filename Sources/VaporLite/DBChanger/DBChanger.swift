//
//  File.swift
//  
//
//  Created by linhey on 2023/7/10.
//

import Foundation
import FluentKit
import STJSON

public protocol DBChanger: AnyObject {
    
    associatedtype Table: DBChangable
    var table_store: (() async throws -> Table)? { get set }
    var database: Database { get }
}

public extension DBChanger {
    
    func table() async throws -> Table {
        guard let table_store = table_store else {
            assertionFailure("未设置 table")
            return try .init(id: nil)
        }
        return try await table_store()
    }
    
    @discardableResult
    func table(_ newValue: @escaping () async throws -> Table) -> Self {
        self.table_store = newValue
        return self
    }
    
    @discardableResult
    func table(_ table: Table?) -> Self {
        guard let table = table else {
            self.table_store = nil
            return self
        }
        return self.table {
            table
        }
    }
    
    @discardableResult
    func table(by id: Table.IDValue) -> Self {
        return table { [weak self] in
            guard let self = self else {
                return try Table.init(id: id)
            }
            if let table = try await Table.find(id, on: self.database) {
                return table
            }
            let table = try Table.init(id: id)
            try await table.save(on: self.database)
            return try await Table.find(id, on: self.database) ?? table
        }
    }
    
}
