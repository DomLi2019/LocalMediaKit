//
//  VideoInfo.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/6.
//

import UIKit
import AVFoundation

public struct VideoInfo: Sendable {
    /// 视频尺寸，经过旋转后的
    public let dimensions: CGSize
    
    /// 时长，秒
    public let duration: TimeInterval
    
    /// 编码格式
    public let codec: String?
    
    /// 帧率
    public let frameRate: Float?
    
    /// 比特率
    public let bitRate: Int?
    
    
    /// 初始化
    public init(
        dimensions: CGSize,
        duration: TimeInterval,
        codec: String? = nil,
        frameRate: Float? = nil,
        bitRate: Int? = nil
    ) {
        self.dimensions = dimensions
        self.duration = duration
        self.codec = codec
        self.frameRate = frameRate
        self.bitRate = bitRate
    }
}
