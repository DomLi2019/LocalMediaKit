//
//  File.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/5.
//

import UIKit


public final class SaveCoordinator: Sendable {
    // MARK: - 依赖
    private let pathManager: PathManager
    private let storageManager: StorageManager
    private let metadataManager: MetadataManager
    private let imageProcessor: ImageProcessor
    private let videoProcessor: VideoProcessor
    private let livePhotoProcessor: LivePhotoProcessor
    
    private let configuration: Configuration
    
    
    
    
    // MARK: - 初始化
    init(
        pathManager: PathManager,
        storageManager: StorageManager = StorageManager(),
        metadataManager: MetadataManager,
        imageProcessor: ImageProcessor = ImageProcessor(),
        videoProcessor: VideoProcessor = VideoProcessor(),
        livePhotoProcessor: LivePhotoProcessor = LivePhotoProcessor()
    ) {
        self.pathManager = pathManager
        self.storageManager = storageManager
        self.metadataManager = metadataManager
        self.imageProcessor = imageProcessor
        self.videoProcessor = videoProcessor
        self.livePhotoProcessor = livePhotoProcessor
    }
}
