//
//  ARInfoController.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/29.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import Foundation
import Alamofire

class ARInfoController {
    
    fileprivate var loadPrevious = host_cpu_load_info() // cpu需要使用
    
    var currentTime: Int    //当前时间 起始时间为0
    let timeInterval: Int  // 信息采集时间间隔
    var cpuList: CpuInfo   // cpu的信息
    var memoryList: MemoryInfo  // 内存信息
    
    // Static Info
    let appId: String = "85d4a553-ee8d-4136-80ab-2469adcae44d"
    let appVersion:String = "2.0"
    let deviceId: String = "iOS"
    let urlServer: String = "http://222.201.145.166:8421/"
    
    
    init() {
        currentTime = 0
        timeInterval = 2
        
        cpuList = CpuInfo.init()
        memoryList = MemoryInfo.init()
    }
    
    func start() {
        baseMobileInfo()
    }
    
    // MARK: - UPLoad
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
        
        requestPost(with: urlCPU, by: parameters)
        print("cpu uploaded")
    }
    
    // And Frame
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
        requestPost(with: urlMemory, by: parameters)
        print("memory uploaded")
        
        // FIXME: Frame
        let urlFrame = urlServer + "ArAnalysis/FrameInfo/receiveFrameInfo"
        
        let parameterFrame: Parameters = [
            "appId": appId,
            "appVersion": appVersion,
            "deviceId": deviceId,
            "collectTime": memory.timeData[0],
            "frameRate": [
                "frameData": [Int.randomIntNumber(lower: 50, upper: 61), Int.randomIntNumber(lower: 54, upper: 61),
                              Int.randomIntNumber(lower: 57, upper: 61), Int.randomIntNumber(lower: 58, upper: 61)],
                "timeData": memory.timeData
            ]
        ]
        requestPost(with: urlFrame, by: parameterFrame)
        print("frame uploaded")
    }
    
    // Custom post method by Alamofire post
    func requestPost(with url: String, by parameters: Parameters) {
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            debugPrint(response)
        }
    }
    
    // MARK: - CPU and Memory
    func baseMobileInfo() {
        Timer.scheduledTimer(timeInterval: Double(self.timeInterval), target: self, selector: Selector(("collectMobileInfo")), userInfo: nil, repeats: true)
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: Selector(("calculateSeconds")), userInfo: nil, repeats: true)
    }
    
    //Get CPU
    func cpuUsage() -> (system: Double, user: Double, idle : Double, nice: Double){
        let load = hostCPULoadInfo();
        
        let usrDiff: Double = Double((load?.cpu_ticks.0)! - loadPrevious.cpu_ticks.0);
        let systDiff = Double((load?.cpu_ticks.1)! - loadPrevious.cpu_ticks.1);
        let idleDiff = Double((load?.cpu_ticks.2)! - loadPrevious.cpu_ticks.2);
        let niceDiff = Double((load?.cpu_ticks.3)! - loadPrevious.cpu_ticks.3);
        
        let totalTicks = usrDiff + systDiff + idleDiff + niceDiff
        print("Total ticks is ", totalTicks);
        let sys = systDiff / totalTicks * 100.0
        let usr = usrDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0
        
        loadPrevious = load!
        
        return (sys, usr, idle, nice);
    }

    @objc func collectMobileInfo() {
        let cpuUserRatio:Double = cpuUsage().user
        let memoryRatio: Double = report_memory().usage * 1024
        let time = calculateUnixTimestamp()
        
        // CPU
        cpuList.cpuData.append(cpuUserRatio)
        cpuList.timeData.append(time)
        
        // Memory
        memoryList.memoryData.append(memoryRatio)
        memoryList.timeData.append(time)
    }
    
    @objc func calculateSeconds() {
        self.currentTime += 1
    }
    
}
