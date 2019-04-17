//
//  UnixTimestampHelper.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/17.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import Foundation

func calculateUnixTimestamp() -> String {
    let timestamp = Int(NSDate().timeIntervalSince1970)
    return String(timestamp * 1000)
}
