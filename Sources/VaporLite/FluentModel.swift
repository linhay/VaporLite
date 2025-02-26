//
//  File.swift
//  
//
//  Created by linhey on 2024/1/26.
//

import Vapor
import Fluent
import STJSON

public extension Model {
    
    func decode<V: Decodable>(_ path: ReferenceWritableKeyPath<Self, String?>, _ type: V.Type) throws -> V {
        guard let data = self[keyPath: path]?.data(using: .utf8) else {
            throw AxError.database_decode
        }
        return try JSONDecoder.shared.decode(type, from: data)
    }
    
}

public extension QueryBuilder {
    
    func stream(size: Int = 1,
                progress: ((_ page: PageMetadata) -> Void)? = nil,
                callback: @escaping ((_ model: Model) async throws -> Void)) async throws {
        let count = try await count()
        guard count > 0 else {
            return
        }
        let max_page_number = count / size + (count % size == 0 ? 0 : 1)
        for index in 1...max_page_number {
            let page = try await self.page(withIndex: index, size: size)
            progress?(page.metadata)
            try await withThrowingTaskGroup(of: Void.self) { group in
                for item in page.items {
                    group.addTask {
                        try await callback(item)
                    }
                }
                try await group.waitForAll()
            }
        }
    }
    
}
