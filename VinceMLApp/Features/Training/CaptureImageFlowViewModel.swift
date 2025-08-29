//
//  CaptureImageFlowViewModel.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 8/13/25.
//

import Foundation
import UIKit
import AVFoundation

/// ViewModel for managing batch image capture flow
/// 
/// Handles the logic for capturing multiple training images in sequence,
/// managing session statistics, and coordinating with the training data service.
///
/// **Responsibilities:**
/// - Manages captured images queue
/// - Handles image saving operations
/// - Tracks capture session statistics
/// - Provides reactive UI state updates
/// - Manages camera capture coordination
///
/// **Usage:**
/// ```swift
/// let captureViewModel = CaptureImageFlowViewModel(
///     trainingViewModel: trainingViewModel,
///     selectedLabel: "Sunglasses"
/// )
/// ```
@MainActor
@Observable
final class CaptureImageFlowViewModel {
    
    // MARK: - Published Properties
    var capturedImages: [UIImage] = []
    var isCapturing: Bool = false
    var sessionStats = CaptureSessionStats()
    var selectedLabel: String
    
    // MARK: - Loading State
    var loadingState = LoadingState.idle
    
    // MARK: - Dependencies
    private let trainingViewModel: TrainingViewModel
    
    // MARK: - Computed Properties
    var hasPendingImages: Bool {
        !capturedImages.isEmpty
    }
    
    var canCapture: Bool {
        !selectedLabel.isEmpty && !isCapturing
    }
    
    var canSaveAll: Bool {
        !capturedImages.isEmpty && !loadingState.isSilentLoading
    }
    
    // MARK: - Initialization
    init(trainingViewModel: TrainingViewModel, selectedLabel: String) {
        self.trainingViewModel = trainingViewModel
        self.selectedLabel = selectedLabel
    }
    
    // MARK: - Public Methods
    /// Handles when an image is successfully captured from the camera
    /// - Parameter image: The captured UIImage
    func handleImageCaptured(_ image: UIImage) {
        guard !selectedLabel.isEmpty else { return }
        
        capturedImages.append(image)
        sessionStats.totalCaptured += 1
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Saves all captured images to the training data
    func saveAllCapturedImages() {
        guard canSaveAll else { return }
        
        Task {
            await saveAllImagesInBackground()
        }
    }
    
    /// Clears all pending captured images
    func clearPendingImages() {
        capturedImages.removeAll()
    }
    
    /// Removes a specific image from the captured images queue
    /// - Parameter index: The index of the image to remove
    func removeImage(at index: Int) {
        guard index < capturedImages.count else { return }
        capturedImages.remove(at: index)
        sessionStats.totalCaptured -= 1
    }
    
    /// Finishes the capture session, saving any pending images
    func finishCaptureSession() {
        if !capturedImages.isEmpty {
            saveAllCapturedImages()
        }
    }
    
    /// Updates the selected label for future captures
    /// - Parameter newLabel: The new label to use for captures
    func updateSelectedLabel(_ newLabel: String) {
        selectedLabel = newLabel
    }
    
    // MARK: - Private Methods
    
    nonisolated private func saveAllImagesInBackground() async {
        let imagesToSave = await MainActor.run { capturedImages }
        let labelToUse = await MainActor.run { selectedLabel }
        
        await MainActor.run {
            loadingState = .silentLoading
        }
        
        do {
            // Save each image through the training view model
            for image in imagesToSave {
                try await trainingViewModel.saveTrainingImageAsync(image, label: labelToUse)
            }
            
            await MainActor.run {
                sessionStats.savedCount += imagesToSave.count
                capturedImages.removeAll()
                loadingState = .idle
            }
            
        } catch {
            await MainActor.run {
                loadingState = .failure("Failed to save images: \(error.localizedDescription)")
            }
        }
    }
    
    func clearLoadingState() {
        loadingState = .idle
    }
    
    private func showError(_ message: String) {
        loadingState = .failure(message)
    }
}

// MARK: - Supporting Types

/// Statistics tracking for a capture session
struct CaptureSessionStats {
    var totalCaptured: Int = 0
    var savedCount: Int = 0
    
    mutating func reset() {
        totalCaptured = 0
        savedCount = 0
    }
}
