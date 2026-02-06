//
//  ImageProcessor.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/1/24.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers


public final class ImageProcessor: ImageProcessing, Sendable {
    /// 专用串行队列
    /// 图片编码解码属于CPU密集型任务，不适合并发，容易内存爆炸
    private let processingQueue: DispatchQueue = DispatchQueue(
        label: "com.localmediakit.imageprocessor",
        qos: .userInitiated
//        attributes: .concurrent
    )
    
    
    // MARK: - 初始化
    public init() {}
    
    
    
    
    // MARK: - 图片编码/解码
    public func decode(_ data: Data) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                guard let image = UIImage(data: data) else {
                    continuation.resume(throwing: MediaKitError.decodingFailed(underlying: nil))
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
    
    public func encode(_ image: UIImage, format: ImageFormat) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    let data = try self.encodeImage(image, format: format)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    
    
    
    // MARK: - 编码私有方法
    
    /// 图片编码成二进制Data
    /// - Parameters:
    ///   - image: 图片
    ///   - format: 图片格式
    /// - Returns: Data
    private func encodeImage(_ image: UIImage, format: ImageFormat) throws -> Data {
        let data: Data?
        
        switch format {
        case .jpeg(let quality):
            data = image.jpegData(compressionQuality: quality!)
             
        case .png:
            data = image.pngData()
            
        case .heic(let quality):
            data = encodeHEIC(image, quality: quality!)
            
        default:
            data = image.jpegData(compressionQuality: 0.7)
        }
        
        guard let encodedData = data else {
            throw MediaKitError.imageEncodingFailed(underlying: nil)
        }
        
        return encodedData
    }
    
    
    /// 编码HEIC格式
    private func encodeHEIC(_ image: UIImage, quality: CGFloat) -> Data? {
        /// 提取UIImage的底层CGImage（Core Graphics像素数据）
        guard let cgImage = image.cgImage else { return nil }
        
        /// 创建可变数据容器，存储编码后的HEIC数据
        let data = NSMutableData()
        
        /// 创建CGImageDestination（图片编码目标），指定输出格式为HEIC
        /// CGImageDestinationCreateWithData 是 Core Graphics 核心编码 API，创建 “图片编码目标”，负责将CGImage转为指定格式的数据流
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,                  /// CFMutableData 是 Core Foundation 类型，适配 CG API
            UTType.heic.identifier as CFString,     /// 指定输出格式为 HEIC
            1,                                      /// 图片帧数（HEIC 是单帧静态图片，因此传1；若为 GIF 则传对应帧数）
            nil                                     /// 编码配置字典，此处传nil使用默认配置
        ) else { return nil }
        
        /// 定义编码选项：设置有损压缩质量
        /// kCGImageDestinationLossyCompressionQuality是 Core Graphics 的系统常量，用于指定 “有损压缩质量”
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        
        /// 将cgImage添加到编码目标，并应用压缩选项
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        /// 完成图片编码操作，将数据写入NSMutableData容器
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        /// 将NSMutableData（Objective-C 兼容类型）转为 Swift 原生的Data类型返回
        return data as Data
    }
    
    
    
    
    // MARK: - 缩略图
    public func thumbnail(at source: ImageSource, targetSize: CGSize) async throws -> UIImage {
        let scale = await MainActor.run { UIScreen.main.scale }
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async {
                do {
                    let thumbnail: UIImage
                    switch source {
                    case .data(let data):
                        thumbnail = try self.downsample(data, to: targetSize, scale: scale)
                    case .url(let url):
                        thumbnail = try self.downsample(url, to: targetSize, scale: scale)
                    }
                    continuation.resume(returning: thumbnail)
                } catch {
                    continuation.resume(throwing: MediaKitError.decodingFailed(underlying: error))
                }
            }
        }
    }
    
    
    
    
    // MARK: - 下采样私有方法，缩略图使用
    /// Data下采样方法
    private func downsample(_ data: Data, to size: CGSize, scale: CGFloat) throws -> UIImage {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            throw MediaKitError.decodingFailed(underlying: nil)
        }
        
        return try downsample(source: source, to: size, scale: scale)
    }
    
    /// url下采样方法
    private func downsample(_ url: URL, to size: CGSize, scale: CGFloat) throws -> UIImage {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else {
            throw MediaKitError.decodingFailed(underlying: nil)
        }
        
        return try downsample(source: source, to: size, scale: scale)
    }
    
    
    /// 下采样方法核心逻辑
    /// - Parameters:
    ///   - source: 图片资源
    ///   - size: 目标的图片尺寸
    /// - Returns: 尺寸调整后的图片
    private func downsample(source: CGImageSource, to size: CGSize, scale: CGFloat) throws -> UIImage {
        /// 计算最大像素尺寸 = 目标尺寸的较大边 × 屏幕缩放因子（如 2x/3x），确保在 Retina 屏幕上清晰。
        /// 比如你希望图片显示尺寸是 200pt（逻辑像素），@3x 屏幕需要 600px（物理像素）的图片才不会模糊
        let maxDimension = max(size.width, size.height) * scale
        
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,     /// 始终创建缩略图，即使原图没有
            kCGImageSourceShouldCacheImmediately: true,             /// 立即缓存生成的缩略图到内存
            kCGImageSourceCreateThumbnailWithTransform: true,       /// 应用 EXIF 旋转信息，保证方向正确
            kCGImageSourceThumbnailMaxPixelSize: maxDimension       /// 缩略图最大像素尺寸
        ]
        
        /// 从图片源的第 0 帧创建缩略图，失败则抛出错误
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            throw MediaKitError.decodingFailed(underlying: nil)
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    
    
    
    // MARK: - 格式
    /// 图片格式检测
    public func detectFormat(from data: Data) -> ImageFormat? {
        guard data.count >= 12 else { return nil }

        let bytes = [UInt8](data.prefix(12))

        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return .jpeg(quality: nil)
        }

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return .png
        }

        // GIF: 47 49 46 38
        if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38 {
            return .gif
        }

        // HEIC: check for ftyp
        if data.count >= 12 {
            let ftypRange = data[4..<8]
            if let ftyp = String(data: ftypRange, encoding: .ascii), ftyp == "ftyp" {
                let brandRange = data[8..<12]
                if let brand = String(data: brandRange, encoding: .ascii) {
                    if brand.hasPrefix("heic") || brand.hasPrefix("mif1") || brand.hasPrefix("heix") {
                        return .heic(quality: nil)
                    }
                }
            }
        }

        // WebP: 52 49 46 46 ... 57 45 42 50
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 {
            if data.count >= 12 {
                let webpBytes = [UInt8](data[8..<12])
                if webpBytes[0] == 0x57 && webpBytes[1] == 0x45 && webpBytes[2] == 0x42 && webpBytes[3] == 0x50 {
                    return .webp
                }
            }
        }

        return .unknown
    }
    
    
    
    
    // MARK: - 尺寸
    public func imageSize(from data: Data) throws -> CGSize {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw MediaKitError.decodingFailed(underlying: nil)
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyWidth] as? Int,
              let height = properties[kCGImagePropertyHeight] as? Int
        else {
            throw MediaKitError.decodingFailed(underlying: nil)
        }
        
        /// 考虑方向
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        let shouldSwap = orientation >= 5 && orientation <= 8
        
        return shouldSwap ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
    }
}
