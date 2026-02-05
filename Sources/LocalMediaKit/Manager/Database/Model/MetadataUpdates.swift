//
//  MetadataUpdates.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/3.
//

import Foundation

/// 媒体元数据更新选项
public struct MetadataUpdates: Sendable {
    public var userInfo: [String: String]
    public var mergeUserInfo: Bool
    
    public init(userInfo: [String : String], mergeUserInfo: Bool = true) {
        self.userInfo = userInfo
        self.mergeUserInfo = mergeUserInfo
    }
}
