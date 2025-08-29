//
//  ClassificationViewModel.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation
import UIKit
import CoreML
import AVFoundation
import VinceML

/// ViewModel responsible for managing image classification operations
/// Handles both single image classification and live camera feed classification
/// Manages ML model loading, camera permissions, and classification state
@MainActor
@Observable
class ClassificationViewModel {
    
    // MARK: - Published Properties
    
    /// The currently loaded Core ML model for classification
    var currentModel: MLModel?
    
    /// Whether a model is currently loaded and ready for classification
    var isModelLoaded: Bool = false
    
    /// The latest classification result as a formatted string
    var classificationResult: String = ""
    
    /// Whether a classification operation is currently in progress
    var isClassifying: Bool = false
    
    /// Whether live classification from camera feed is enabled
    var isLiveClassificationEnabled: Bool = false
    
    /// Loading state for operations
    var loadingState = LoadingState.idle
    
    /// Whether the app has camera permission
    var hasCameraPermission: Bool = false
    
    // MARK: - Private Properties
    
    /// Timestamp of the last classification to implement throttling
    private var lastClassificationTime: Date = Date()
    
    /// Minimum interval between live classifications to prevent overwhelming the system
    private let classificationInterval: TimeInterval = 0.1
    
    // MARK: - Dependencies
    
    /// Service for ML model operations and image classification
    private let mlModelService: MLModelServiceProtocol
    
    /// Manager for ML model loading and persistence
    private let modelManager: ModelManagerProtocol
    
    /// Service for camera permission management
    private let cameraService: CameraServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes the classification view model with required dependencies
    /// - Parameters:
    ///   - mlModelService: Service for ML operations
    ///   - modelManager: Manager for model loading
    ///   - cameraService: Service for camera permissions
    init(
        mlModelService: MLModelServiceProtocol,
        modelManager: ModelManagerProtocol,
        cameraService: CameraServiceProtocol
    ) {
        self.mlModelService = mlModelService
        self.modelManager = modelManager
        self.cameraService = cameraService
        
        Task {
            await checkCameraPermission()
        }
    }
    
    // MARK: - Public Methods
    
    /// Classifies a single image using the current model
    /// - Parameter image: The image to classify
    func classifyImage(_ image: UIImage) {
        guard let model = currentModel else {
            loadingState = .failure("No model available. Please train a model first using the training tab.")
            return
        }
        
        Task {
            await classifyImageInBackground(image, using: model)
        }
    }
    
    /// Classifies an image from the live camera feed with throttling
    /// - Parameter image: The image to classify
    func classifyImageLive(_ image: UIImage) {
        // Throttle live classification to avoid overwhelming the system
        let now = Date()
        guard now.timeIntervalSince(lastClassificationTime) >= classificationInterval else {
            return
        }
        lastClassificationTime = now
        
        guard let model = currentModel else {
            return
        }
        
        Task {
            await classifyImageLiveInBackground(image, using: model)
        }
    }
    
    /// Starts live classification from camera feed
    func startLiveClassification() {
        Task {
            await loadCurrentModel()
            isLiveClassificationEnabled = true
        }
    }
    
    /// Stops live classification and clears results
    func stopLiveClassification() {
        isLiveClassificationEnabled = false
        clearResult()
    }
    
    /// Toggles live classification on/off
    func toggleLiveClassification() {
        if isLiveClassificationEnabled {
            stopLiveClassification()
        } else {
            startLiveClassification()
        }
    }
    
    /// Reloads the current model
    func loadModel() {
        Task {
            await loadCurrentModel()
        }
    }
    
    /// Requests camera permission from the user
    func requestCameraPermission() {
        Task {
            await requestCameraPermissionInBackground()
        }
    }
    
    /// Clears the current classification result
    func clearResult() {
        classificationResult = ""
    }
    
    func clearLoadingState() {
        loadingState = .idle
    }
    
    // MARK: - Private Methods
    
    /// Displays an error message to the user
    /// - Parameter message: The error message to display
    private func showError(_ message: String) {
        loadingState = .failure(message)
    }
    
    // MARK: - Background Operations
    
    /// Performs image classification on a background task for single images
    /// - Parameters:
    ///   - image: The image to classify
    ///   - model: The ML model to use for classification
    nonisolated private func classifyImageInBackground(_ image: UIImage, using model: MLModel) async {
        await MainActor.run {
            isClassifying = true
        }
        
        // Convert UIImage to VinceMLImage for platform-agnostic processing
        let vinceMLImage: VinceMLImage = image
        
        // Use MLModelService for classification with confidence scores
        let results = await mlModelService.classifyImage(vinceMLImage, using: model)
        
        await MainActor.run {
            if let topResult = results.first {
                classificationResult = topResult
            } else {
                classificationResult = "No classification available"
            }
            isClassifying = false
        }
    }
    
    /// Performs image classification on a background task for live camera feed
    /// - Parameters:
    ///   - image: The image to classify
    ///   - model: The ML model to use for classification
    nonisolated private func classifyImageLiveInBackground(_ image: UIImage, using model: MLModel) async {
        // Don't set isClassifying for live classification to avoid UI flickering
        
        // Use MLModelService for classification with confidence scores
        let results = await mlModelService.classifyImage(image, using: model)
        
        await MainActor.run {
            if let topResult = results.first {
                classificationResult = topResult
            } else {
                classificationResult = "No classification available"
            }
        }
    }
    
    /// Loads the current model from the model manager
    nonisolated private func loadCurrentModel() async {
        do {
            let model = await modelManager.getCurrentModel()
            
            await MainActor.run {
                currentModel = model
                isModelLoaded = model != nil
            }
        }
    }
    
    /// Checks current camera permission status
    nonisolated private func checkCameraPermission() async {
        let hasPermission = await cameraService.checkCameraPermission()
        
        await MainActor.run {
            hasCameraPermission = hasPermission
        }
    }
    
    /// Requests camera permission from the user
    nonisolated private func requestCameraPermissionInBackground() async {
        let granted = await cameraService.requestCameraPermission()
        
        await MainActor.run {
            hasCameraPermission = granted
            if !granted {
                loadingState = .failure("Camera permission is required for classification")
            }
        }
    }
}
