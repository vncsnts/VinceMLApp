//
//  ImageGridItem.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 8/13/25.
//

import SwiftUI
import Foundation
import VinceML

/// A generic, reusable image grid item component with memory-efficient image loading
///
/// This component uses thumbnail caching and image downsampling to prevent memory spikes
/// when scrolling through large image collections.
///
/// **Usage:**
/// ```swift
/// // For training images
/// ImageGridItem(
///     imageProvider: .trainingImage(image, modelName: modelName),
///     showDate: true,
///     onDelete: { deleteAction() }
/// )
///
/// // For captured images
/// ImageGridItem(
///     imageProvider: .uiImage(capturedImage),
///     showDate: false,
///     onDelete: { deleteAction() }
/// )
/// ```
struct ImageGridItem: View {
    let imageProvider: ImageProvider
    let showDate: Bool
    let size: CGSize
    let onDelete: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var isLoading = false
    
    // Shared thumbnail cache
    private static let thumbnailCache = NSCache<NSString, UIImage>()
    
    init(
        imageProvider: ImageProvider,
        showDate: Bool = false,
        size: CGSize = CGSize(width: 100, height: 100),
        onDelete: @escaping () -> Void
    ) {
        self.imageProvider = imageProvider
        self.showDate = showDate
        self.size = size
        self.onDelete = onDelete
        
        // Configure cache
        Self.thumbnailCache.countLimit = 100 // Limit number of cached thumbnails
        Self.thumbnailCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Use cached thumbnail or placeholder
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .cornerRadius(8)
                } else if isLoading {
                    // Loading placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: size.width, height: size.height)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                } else {
                    // Error placeholder
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .frame(width: size.width, height: size.height)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                        .font(.caption)
                }
                .padding(4)
            }
            
            if showDate, let date = imageProvider.dateCreated {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .onDisappear {
            // Cancel any ongoing loading if needed
            isLoading = false
        }
    }
    
    private func loadThumbnail() {
        // Create cache key
        let cacheKey = getCacheKey()
        
        // Check cache first
        if let cachedThumbnail = Self.thumbnailCache.object(forKey: cacheKey) {
            thumbnail = cachedThumbnail
            return
        }
        
        // Load thumbnail asynchronously
        isLoading = true
        
        Task {
            let loadedThumbnail = await loadThumbnailAsync()
            
            await MainActor.run {
                isLoading = false
                thumbnail = loadedThumbnail
                
                // Cache the thumbnail if successfully loaded
                if let loadedThumbnail = loadedThumbnail {
                    Self.thumbnailCache.setObject(loadedThumbnail, forKey: cacheKey)
                }
            }
        }
    }
    
    private func getCacheKey() -> NSString {
        switch imageProvider {
        case .uiImage(let image):
            // Use image hash or memory address as key for UIImage
            return NSString(string: "\(image.hashValue)")
        case .trainingImage(let trainingImage, let modelName):
            return NSString(string: "\(modelName ?? "unknown")_\(trainingImage.fileName)")
        }
    }
    
    private func loadThumbnailAsync() async -> UIImage? {
        switch imageProvider {
        case .uiImage(let image):
            return await createThumbnail(from: image)
        case .trainingImage(let trainingImage, let modelName):
            return await loadTrainingImageThumbnail(trainingImage: trainingImage, modelName: modelName)
        }
    }
    
    private func createThumbnail(from image: UIImage) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let thumbnailSize = CGSize(
                    width: self.size.width * UIScreen.main.scale,
                    height: self.size.height * UIScreen.main.scale
                )
                
                let thumbnail = image.preparingThumbnail(of: thumbnailSize)
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func loadTrainingImageThumbnail(trainingImage: TrainingImage, modelName: String?) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let imageURL = self.constructImageURL(for: trainingImage, modelName: modelName)
                
                guard FileManager.default.fileExists(atPath: imageURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Create thumbnail using ImageIO for memory efficiency
                let thumbnail = self.createThumbnailFromFile(at: imageURL)
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func createThumbnailFromFile(at url: URL) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        
        let thumbnailSize = CGSize(
            width: size.width * UIScreen.main.scale,
            height: size.height * UIScreen.main.scale
        )
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(thumbnailSize.width, thumbnailSize.height)
        ]
        
        guard let thumbnailImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: thumbnailImage)
    }
    
    private func constructImageURL(for trainingImage: TrainingImage, modelName: String?) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Try VinceML structure first if we have any model name
        if let modelName = modelName, !modelName.isEmpty {
            let vinceMLModelsDirectory = documentsDirectory.appendingPathComponent("VinceML_Models")
            let modelDirectory = vinceMLModelsDirectory.appendingPathComponent(modelName)
            let imagesDirectory = modelDirectory.appendingPathComponent("Images")
            let labelDirectory = imagesDirectory.appendingPathComponent(trainingImage.label)
            let vinceMLPath = labelDirectory.appendingPathComponent(trainingImage.fileName)
            
            // Check if file exists in VinceML structure
            if FileManager.default.fileExists(atPath: vinceMLPath.path) {
                return vinceMLPath
            }
        }
        
        // Try legacy aims-vision structure if we have any model name
        if let modelName = modelName, !modelName.isEmpty {
            let modelsDirectory = documentsDirectory.appendingPathComponent("Models")
            let modelDirectory = modelsDirectory.appendingPathComponent(modelName)
            let imagesDirectory = modelDirectory.appendingPathComponent("Images")
            let labelDirectory = imagesDirectory.appendingPathComponent(trainingImage.label)
            let legacyPath = labelDirectory.appendingPathComponent(trainingImage.fileName)
            
            // Check if file exists in legacy structure
            if FileManager.default.fileExists(atPath: legacyPath.path) {
                return legacyPath
            }
        }
        
        // Try old training images structure as fallback
        let trainingImagesDirectory = documentsDirectory.appendingPathComponent("TrainingImages")
        let labelDirectory = trainingImagesDirectory.appendingPathComponent(trainingImage.label)
        let oldPath = labelDirectory.appendingPathComponent(trainingImage.fileName)
        
        if FileManager.default.fileExists(atPath: oldPath.path) {
            return oldPath
        }
        
        // Default to VinceML structure for new files
        if let modelName = modelName, !modelName.isEmpty {
            let vinceMLModelsDirectory = documentsDirectory.appendingPathComponent("VinceML_Models")
            let modelDirectory = vinceMLModelsDirectory.appendingPathComponent(modelName)
            let imagesDirectory = modelDirectory.appendingPathComponent("Images")
            let labelDirectory = imagesDirectory.appendingPathComponent(trainingImage.label)
            return labelDirectory.appendingPathComponent(trainingImage.fileName)
        }
        
        // Final fallback to old structure
        return oldPath
    }
}

/// Enum to provide different types of images to the ImageGridItem
/// This follows the Open/Closed Principle - open for extension, closed for modification
enum ImageProvider {
    case uiImage(UIImage)
    case trainingImage(TrainingImage, modelName: String?)
    
    var dateCreated: Date? {
        switch self {
        case .uiImage:
            return nil
        case .trainingImage(let trainingImage, _):
            return trainingImage.dateCreated
        }
    }
}
