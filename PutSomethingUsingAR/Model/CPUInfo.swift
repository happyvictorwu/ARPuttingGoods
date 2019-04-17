//
//  CPUInfo.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/15.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import Foundation

struct CpuInfo {
    let collectTime: String = ""
    let cpuData: [Int] = []
    let timeData: [Int] = []
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
