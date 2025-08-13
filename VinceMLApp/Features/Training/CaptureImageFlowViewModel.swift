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
    var errorMessage: String?
    var showingError: Bool = false
    var isProcessingSave: Bool = false
    
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
        !capturedImages.isEmpty && !isProcessingSave
    }
    
    // MARK: - Initialization
    init(trainingViewModel: TrainingViewModel, selectedLabel: String) {
        self.trainingViewModel = trainingViewModel
        self.selectedLabel = selectedLabel
    }
    
    // MARK: - Public Methods
    
    /// Initiates the image capture process
    func captureImage() {
        guard canCapture else { return }
        
        isCapturing = true
        
        // Reset capturing state after a short delay to provide visual feedback
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                isCapturing = false
            }
        }
    }
    
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
            isProcessingSave = true
        }
        
        do {
            // Save each image through the training view model
            for image in imagesToSave {
                try await trainingViewModel.saveTrainingImageAsync(image, label: labelToUse)
            }
            
            await MainActor.run {
                sessionStats.savedCount += imagesToSave.count
                capturedImages.removeAll()
                isProcessingSave = false
                
                // Provide success feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
            
        } catch {
            await MainActor.run {
                isProcessingSave = false
                showError("Failed to save images: \(error.localizedDescription)")
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
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
