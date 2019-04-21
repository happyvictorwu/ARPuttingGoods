//
//  uploadInfo.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/19.
//  Copyright © 2019 Victor Wu. All rights reserved.
//
import Foundation
import Alamofire

let appId: String = "1233211234567"
let appVersion:String = "v1.0"
let deviceId: String = "iOS"
let urlServer: String = "http://222.201.145.166:8421/"

func uploadCPU(cpu: CpuInfo, urlTail: String) {
    guard !cpu.isEmpty() else { return }
    
    let urlCPU = urlServer + urlTail
    
    let parameters: Parameters = [
        "appId": appId,
        "appVersion": appVersion,
        "deviceId": deviceId,
        "collectTime": cpu.timeData[0],
        "cpuUsage": [
            "cpuData": cpu.cpuData,
            "timeData": cpu.timeData
        ]
    ]
    
    Alamofire.request(urlCPU, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
        debugPrint(response)
    }
    print("cpu uploaded")
}

func uploadMemory(memory: MemoryInfo, urlTail: String) {
    guard !memory.isEmpty() else { return }
    
    let urlMemory = urlServer + urlTail
    
    let parameters: Parameters = [
        "appId": appId,
        "appVersion": appVersion,
        "deviceId": deviceId,
        "collectTime": memory.timeData[0],
        "runtimeMemory": [
            "memoryData": memory.memoryData,
            "timeData": memory.timeData
        ]
    ]
    Alamofire.request(urlMemory, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
        debugPrint(response)
    }
    print("memory uploaded")
}

func uploadTriggerCount(furniture: [Action], urlTail: String) {
    // calculate the number of all Action
    let ScalingCount: Int = countAction(in: furniture, with: Action.Scaling)
    let RotateCount: Int = countAction(in: furniture, with: Action.Rotate)
    let AddCount: Int = countAction(in: furniture, with: Action.Add)
    
    let urlTrigger = urlServer + urlTail
    
    let parameters: Parameters = [
        "appId": appId,
        "appVersion": appVersion,
        "deviceId": deviceId,
        "info": [
            "缩放(Scaling)": ScalingCount,
            "旋转(Rotate)": RotateCount,
            "添加(Add)": AddCount
        ]
    ]
    
    Alamofire.request(urlTrigger, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
        debugPrint(response)
    }
    print("TriggerCount uploaded")
    print("Scaling: \(ScalingCount)")
    print("Rotate: \(RotateCount)")
    print("Add: \(AddCount)")
    
}


func uploadGazeObject(furniture: Furniture, urlTail: String) {
    let urlGaze = urlServer + urlTail
    let modelName: String = furniture.modelName
    let gazeTime: Int = furniture.costTime
    
    let parameters: Parameters = [
        "appId": appId,
        "appVersion": appVersion,
        "deviceId": deviceId,
        "info": [
            modelName: gazeTime
        ]
    ]
    
    Alamofire.request(urlGaze, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
        debugPrint(response)
    }
}

func uploadInteractionLostInfo(furniture: Furniture, urlTail: String) {
    let urlInteraction = urlServer + urlTail
    let modelName: String = furniture.modelName
//    var furnitureToString: [String] = []
    
    for item in furniture.actionInteractList {
//        furnitureToString.append(item.description)
        let action: String = item.description
        
        let parameters: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "interactList": [
                ["model": modelName, "method": action],
            ]
        ]
        
        Alamofire.request(urlInteraction, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            debugPrint(response)
        }
    }
    
//    let parameters: Parameters = [
//        "appId": appId,
//        "appVersion": appVersion,
//        "deviceId": deviceId,
//        "info": [
//            modelName: furnitureToString[0]
//        ]
//    ]
//
//    Alamofire.request(urlInteraction, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
//        debugPrint(response)
//    }
    
}

// MARK: - Helpper
func countAction(in furniture: [Action], with action: Action) -> Int {
    var ans = 0
    
    for item in furniture {
        if item == action {
            ans += 1
        }
    }
    
    return ans
}
