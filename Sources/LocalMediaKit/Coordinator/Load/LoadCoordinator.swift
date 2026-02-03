//
//  LoadCoordinator.swift
//  媒体加载协调器类，负责所有加载流程协调
//
//  Created by 庄七七 on 2026/2/1.
//

import Foundation


/// 加载协调器
public final class LoadCoordinator: Sendable {
    private let pathManager: PathManager
    private let storageManager: StorageManager
//    private let metaDataManager: MetadataManager
    private let imageProcessor: ImageProcessor
//    private let videoProcessor: VideoProcessing
//    private let livePhotoProcessor: LivePhotoProcessing
//    private let
    
    
    init(pathManager: PathManager, storageManager: StorageManager, imageProcessor: ImageProcessor) {
        self.pathManager = pathManager
        self.storageManager = storageManager
        self.imageProcessor = imageProcessor
    }
    
    
    
    
    // MARK: - 加载
    
    func load(_ request: LoadRequest) async throws -> MediaResource {
        
    }
}
