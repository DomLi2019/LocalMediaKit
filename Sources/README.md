#  LocalMediaKit

提供的能力：
保存：
1. 图片存储，存储原图、1.0jpg图，0.5尺寸0.7质量jpg图、复制图片文件
2、生成缩略图
3、保存实况图（写入视频+实况图并关联）
4、保存视频（copy方式）
        


加载：
1、加载图片
2、加载实况图
3、加载视频、视频缩略图
4、提供媒体url，比如给Kingfisher使用，但这可能反而让缓存策略不受控

缓存：
1、缩略图缓存
2、媒体宽高尺寸缓存


删除：
1、删除媒体文件


路径管理：
1、根目录名称
2、图片、实况图、视频目录名称
    图片：
    let imageId = UUID().uuidString
    let imageFileName = "\(imageId)_\(originalFileName)"
    let imagePath = getImagePath(fileName: imageFileName)

    实况：
    let livePhotoId = UUID().uuidString
    let imageFileName = "\(livePhotoId)_image.jpg"
    let videoFileName = "\(livePhotoId)_video.mov"
    
    let imagePath = getLivePhotoPath(fileName: imageFileName)
    let videoPath = getLivePhotoPath(fileName: videoFileName)

    视频：
    let videoId = UUID().uuidStringlet ext = (videoURL.pathExtension.isEmpty ? "mp4" : videoURL.pathExtension).lowercased()
    let videoFileName = "\(videoId).\(ext)"
    let thumbnailFileName = "\(videoId)_thumb.jpg"
    
    let videoPath = getVideoPath(fileName: videoFileName)
    let thumbnailPath = getVideoPath(fileName: thumbnailFileName)


技术路径：
图片：               
PHPickerResult -> result.itemProvider.loadObject(ofClass: UIImage.self)
保存：
PHAsset -> PHAssetResource.assetResources(for: asset) -> PHAssetResourceManager.default().writeData(for: imageRes, toFile: imagePath, options: nil)
实况图：
PHPickerResult -> result.itemProvider.loadObject(ofClass: PHLivePhoto.self)
保存：
PHAsset -> PHAssetResource.assetResources(for: asset) -> PHAssetResourceManager.default().writeData(for: imageRes, toFile: imagePath, options: nil)

视频：
PHPickerResult.assetIdentifier -> PHAsset -> imageManager.requestAVAsset(forVideo: asset, options: options)
                               -> result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier)
保存：
videoURL -> FileManager.default.copyItem(at: videoURL, to: videoPath)
UIImage -> thumbnailData.write(to: thumbnailPath)
