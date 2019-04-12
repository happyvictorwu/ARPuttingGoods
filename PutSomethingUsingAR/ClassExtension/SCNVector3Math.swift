//
//  SCNVector3Math.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/9.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import SceneKit

func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

extension SCNVector3 {
    
    // 计算向量的长度，通过三维欧拉距离
    func length() -> Float {
        return sqrtf( x*x + y*y + z*z )
    }
    
    // 与另外一条向量的距离
    func distanceTo(_ other: SCNVector3) -> Float {
        return SCNVector3(x: self.x - other.x, y: self.y - other.y, z: self.z - other.z).length()
    }
}
