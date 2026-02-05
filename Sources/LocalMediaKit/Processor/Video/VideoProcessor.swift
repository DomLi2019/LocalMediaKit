//
//  VideoProcessor.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/5.
//

import UIKit
import AVFoundation

/// 视频处理器
public final class VideoProcessor: Sendable {
    /// 处理队列
    private let processingQueue = DispatchQueue(
        label: "com.localmediakit.videoprocessor",
        qos:.userInitiated
    )
    
    
    // MARK: - 初始化
    public init() {}
    
    
    
    
    // MARK: - 视频处理
    
    /// 提取视频截图
    public func extractThumbnail(from url: URL, at time: CMTime? = nil) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    /// 基于url创建视频资源对象，能解析视频/音频的元数据、轨道信息等
                    let asset = AVURLAsset(url: url)
                    /// 创建视频资源的缩略图生成器
                    /// AVAssetImageGenerator 是 AVFoundation 专门用于从视频中提取单帧图片（缩略图）的类
                    let generator = AVAssetImageGenerator(asset: asset)
                    /// 应用旋转效果
                    generator.appliesPreferredTrackTransform = true
                    /// 设置缩略图宽高最大不超过1024
                    generator.maximumSize = CGSize(width: 1024, height: 1024)
                    /// 获取截图的时间，如果没有就用0秒。600表示把秒分成600份，作为时间刻度。
                    let actualTime = time ?? CMTime(seconds: 0, preferredTimescale: 600)
                    /// 截图
                    let cgImage = try generator.copyCGImage(at: actualTime, actualTime: nil)
                    /// 创建UIImage
                    let image = UIImage(cgImage: cgImage)
                    /// 返回图片
                    continuation.resume(returning: image)
                } catch {
                    continuation.resume(throwing: MediaKitError.decodingFailed(underlying: error))
                }
            }
        }
    }
    
    
    /// 视频时长
    public func duration(from url: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            return duration.seconds
        } catch {
            throw MediaKitError.invalidVideo(reason: error.localizedDescription)
        }
    }
    
    
    /// 获取视频路径的拓展名
    public func detectVideoFormat(at url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "mp4", "m4v":
            return "mp4"
        case "mov":
            return "mov"
        case "avi":
            return "avi"
        case "mkv":
            return "mkv"
        default:
            return ext
        }
    }
}
