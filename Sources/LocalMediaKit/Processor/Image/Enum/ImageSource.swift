//
//  ImageSource.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/1/31.
//

import Foundation


/// 图片来源
public enum ImageSource: Sendable {
    /// 从数据
    case data(Data)
    
    /// 从文件URL
    case url(URL)
}
