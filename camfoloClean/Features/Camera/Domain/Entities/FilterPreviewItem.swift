// Features/Camera/Domain/Entities/FilterPreviewItem.swift
import Foundation
import GPUImage

public struct FilterPreviewItem: Identifiable {
    public let id: String
    public let name: String
    public let filter: BasicOperation
    
    public init(id: String, name: String, filter: BasicOperation) {
        self.id = id
        self.name = name
        self.filter = filter
    }
}
