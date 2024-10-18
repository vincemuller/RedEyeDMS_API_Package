//
//  File.swift
//  
//
//  Created by Vince Muller on 10/17/24.
//

import Foundation

public struct ErrorResponse: Codable {
    public var error: String
    public var title: String
}

public struct Errors: Codable, Identifiable {
    public var id = UUID()
    public var errors: [ErrorResponse]
}

public struct Group: Codable {
    
    public var id: Int
    public var name: String
}

public struct Metadata: Codable {
    public var description: String
    public var id: Int
    public var name: String
}

public struct Record: Identifiable {
    public init(filepath: String, sha256: String, artefactType: String, targetGroup: String, workflow: String, drawingNum: String, drawingTitle: String, metadata: [Metadata], manifestBatchID: UUID, id: UUID = UUID()) {
        self.filepath = filepath
        self.sha256 = sha256
        self.artefactType = artefactType
        self.targetGroup = targetGroup
        self.workflow = workflow
        self.drawingNum = drawingNum
        self.drawingTitle = drawingTitle
        self.metadata = metadata
        self.manifestBatchID = manifestBatchID
        self.id = id
    }
    public var filepath: String = ""
    public var sha256: String = ""
    public var artefactType: String = ""
    public var targetGroup: String = ""
    public var workflow: String = ""
    public var drawingNum: String = ""
    public var drawingTitle: String = ""
    public var metadata: [Metadata] = []
    public var manifestBatchID: UUID = UUID()
    public var id = UUID()
}
