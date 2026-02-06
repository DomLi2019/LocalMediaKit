//
//  ImageProcessing.swift
//  LocalMediaKit
//
//  Created by 庄七七 on 2026/2/6.
//

import UIKit

public protocol ImageProcessing: Sendable {
    func decode(_ data: Data) async throws -> UIImage
    func encode(_ image: UIImage, format: ImageFormat) async throws -> Data
    func thumbnail(at source: ImageSource, targetSize: CGSize) async throws -> UIImage
    func detectFormat(from data: Data) -> ImageFormat?
    func imageSize(from data: Data) throws -> CGSize
}
