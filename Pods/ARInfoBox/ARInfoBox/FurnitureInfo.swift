//
//  FurnitureInfo.swift
//  ARInfoBox
//
//  Created by Victor Wu on 2019/5/8.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import Foundation

public struct Furniture {
    public var modelName: String
    public var actionInteractList: [Action]
    public var costTime: Int
    
    public init() {
        modelName = "unknow"
        actionInteractList = []
        costTime = 0
    }
    
    public mutating func resetItself() {
        modelName = "unknow"
        actionInteractList.removeAll()
        costTime = 0
    }
}
