//
//  SCNNodeHelpers.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/9.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import SceneKit
import ARKit

// 返回识别到anchor后的平面
// center是屏幕中心所在的三维坐标，传入的是ARPlaneAnchor的extent值，是水平平面的所以是x和z
func createPlaneNode(center: vector_float3, extent: vector_float3) -> SCNNode {
    
    let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
    
    let planeMaterial = SCNMaterial()
    planeMaterial.diffuse.contents = UIColor.blue.withAlphaComponent(0.7)
    plane.materials = [planeMaterial]
    
    let planeNode = SCNNode(geometry: plane)    // 设置这个Node为上述的平面， 默认是打竖的
    planeNode.position = SCNVector3Make(center.x, 0, center.z)
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)    // 根据x轴来 counter-clockwise 180度
    
    return planeNode
}

// 随着屏幕的移动，根据Anchor的位置和大小，更新传入node的大小和位置
func updatePlaneNode(_ node: SCNNode, center: vector_float3, extent: vector_float3) {
    
    let geometry = node.geometry as! SCNPlane
    
    // 更新宽高
    geometry.width = CGFloat(extent.x)
    geometry.height = CGFloat(extent.z)
    
    // 更新位置
    node.position = SCNVector3Make(center.x, 0, center.z)
}

func removeChildren(inNode node: SCNNode) {
    
    for node in node.childNodes {
        node.removeFromParentNode()
    }
}