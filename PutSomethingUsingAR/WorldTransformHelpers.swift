//
//  WorldTransformHelpers.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/10.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import ARKit

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
