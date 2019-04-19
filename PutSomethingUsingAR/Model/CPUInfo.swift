//
//  CPUInfo.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/15.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import Foundation

struct CpuInfo {
    var cpuData: [Double] = []
    var timeData: [String] = []
    
    func isEmpty() -> Bool {
        guard cpuData.count == timeData.count else { print("check cpuData.count(\(cpuData.count)) no equial to timeData.count(\(timeData.count))"); return true}
        return cpuData.isEmpty
    }
    
    mutating func resetAll() {
        self.cpuData.removeAll()
        self.timeData.removeAll()
    }
}

func hostCPULoadInfo() -> host_cpu_load_info? {
    let HOST_CPU_LOAD_INFO_COUNT = MemoryLayout<host_cpu_load_info>.stride/MemoryLayout<integer_t>.stride
    var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
    var cpuLoadInfo = host_cpu_load_info()
    
    let result = withUnsafeMutablePointer(to: &cpuLoadInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: HOST_CPU_LOAD_INFO_COUNT) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }
    }
    if result != KERN_SUCCESS{
        print("Error  - \(#file): \(#function) - kern_result_t = \(result)")
        return nil
    }
    return cpuLoadInfo
}
