//
//  CacheCategory.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/4.
//

import Foundation


/// 缓存分类，用于区分缓存路径
public enum CacheCategory: String, Sendable {
    case thumbnail
    case processedImage
    case temp
}
