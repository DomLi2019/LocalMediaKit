//
//  VideoProcessor.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/5.
//

import UIKit
import AVFoundation

/// 视频处理器
public final class VideoProcessor: VideoProcessing, Sendable {
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
                    let image = try self.extractThumbnail(from: url, at: time)
                    continuation.resume(returning: image)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 同步提取视频截图
    public func extractThumbnail(from url: URL, at time: CMTime? = nil) throws -> UIImage {
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
            return image
        } catch {
            throw MediaKitError.decodingFailed(underlying: error)
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
    
    
    /// 视频信息提取
    /// - Parameter url: <#url description#>
    /// - Returns: <#description#>
    public func videoInfo(of url: URL) async throws -> VideoInfo {
        let asset = AVURLAsset(url: url)
        
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)      /// 加载视频的所有视频轨道
        
        /// 校验是否存在有效视频轨道
        guard let track = tracks.first else {
            debugPrint("[videoInfo] no video track found")
            throw MediaKitError.invalidVideo(reason: "No video track found")
        }
        
        /// 加载视频轨道AVAssetTrack核心属性
        let size = try await track.load(.naturalSize)       /// 视频轨道的原生宽高
        let transform = try await track.load(.preferredTransform)           /// 视频轨道的首选变换矩阵
        let nominalFrameRate = try await track.load(.nominalFrameRate)      /// 视频的帧率
        let estimatedDataRate = try await track.load(.estimatedDataRate)    /// 视频的预估码率
        
        let formatDescriptions = try await track.load(.formatDescriptions)
        var codec: String?
        if let formatDescription = formatDescriptions.first {
            let codecType = CMFormatDescriptionGetMediaSubType(formatDescription)
            codec = codecName(for: codecType)
        }
        
        /// 修正视频旋转后的实际宽高
        let transformedSize = size.applying(transform)
        let correctedSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))
        
        return VideoInfo(
            dimensions: correctedSize,
            duration: duration.seconds,
            codec: codec,
            frameRate: nominalFrameRate,
            bitRate: Int(estimatedDataRate)
        )
    }
    
    
    private func codecName(for fourCC: FourCharCode) -> String {
        switch fourCC {
        case kCMVideoCodecType_H264:
            return "H.264"
        case kCMVideoCodecType_HEVC:
            return "HEVC"
        case kCMVideoCodecType_MPEG4Video:
            return "MPEG-4"
        case kCMVideoCodecType_AppleProRes422:
            return "ProRes 422"
        case kCMVideoCodecType_AppleProRes4444:
            return "ProRes 4444"
        default:
            // 将 FourCC 转为字符串
            let bytes: [UInt8] = [
                UInt8(truncatingIfNeeded: (fourCC >> 24) & 0xFF),
                UInt8(truncatingIfNeeded: (fourCC >> 16) & 0xFF),
                UInt8(truncatingIfNeeded: (fourCC >> 8) & 0xFF),
                UInt8(truncatingIfNeeded: fourCC & 0xFF)
            ]
            return String(decoding: bytes, as: UTF8.self)
        }
    }
    
    
    public func isValid(at url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        do {
            let isPlayable = try await asset.load(.isPlayable)
            return isPlayable
        } catch {
            return false 
        }
    }
}
