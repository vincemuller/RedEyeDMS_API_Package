//
//  File.swift
//  
//
//  Created by Vince Muller on 10/17/24.
//

import Foundation

public struct ErrorResponse: Codable {
    var error: String
    var title: String
}

public struct Errors: Codable, Identifiable {
    public var id = UUID()
    var errors: [ErrorResponse]
}

public struct Group: Codable {
    var id: Int
    var name: String
}

public struct BucketMetadata: Codable {
    var description: String
    var id: Int
    var name: String
}

public struct File: Identifiable {
    var filepath: String = ""
    var sha256: String = ""
    var artefactType: String = ""
    var targetGroup: String = ""
    var workflow: String = ""
    var drawingNum: String = ""
    var drawingTitle: String = ""
    var metadata: [BucketMetadata] = []
    var manifestBatchID: UUID = UUID()
    public var id = UUID()
}
