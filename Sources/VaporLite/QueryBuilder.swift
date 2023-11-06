//
//  File.swift
//  
//
//  Created by linhey on 2023/4/8.
//

import Foundation
import Fluent

public extension QueryBuilder {
    
    func first(id: Model.IDValue?) async throws -> Model? {
        guard let id = id else { return nil }
        return try await self.filter(\._$id, .equal, id).first()
    }
    
}
