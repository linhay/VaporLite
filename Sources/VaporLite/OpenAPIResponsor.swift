//
//  File.swift
//
//
//  Created by linhey on 2023/4/6.
//

import Foundation
import Vapor

public struct OpenAPIResponsor<Item: Codable>: Codable, Content {
    
    public struct Result: Codable {
        public let item: Item
    }
    
    public let results: Result
    
    public init(_ item: Item) {
        self.results = .init(item: item)
    }
    
}
