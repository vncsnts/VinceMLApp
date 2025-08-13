//
//  TrainingViewModel.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation
import UIKit
import CoreML
import VinceML

/// ViewModel for managing machine learning model training operations
///
/// Coordinates the complete model training workflow including:
/// - Training data collection and organization
/// - Label management and validation
/// - Model training process with progress tracking
/// - Integration with camera for image capture
/// - Error handling and user feedback
///
/// **Training Workflow:**
/// 1. Select or create model
/// 2. Add labels and capture training images
/// 3. Ensure minimum training data requirements (5+ images per label)
/// 4. Execute training with progress monitoring
/// 5. Handle completion and error states
///
/// **State Management:**
/// - Observable properties for real-time UI updates
/// - Async operations with proper error handling
/// - Progress tracking for long-running training operations
///
/// **Integration Points:**
/// - `ModelManager` for model lifecycle operations
/// - `TrainingDataService` for image and label management
/// - `MLModelService` for actual training execution
/// - `CameraService` for permission and capture operations
@MainActor
@Observable
final class TrainingViewModel {
    
    // MARK: - Published Properties
    var trainingImages: [TrainingImage] = []
    var availableLabels: Set<String> = []
    var selectedLabel: String = ""
    var selectedModelName: String?
    var isTraining: Bool = false
    var trainingProgress: Double = 0.0
    var errorMessage: String?
    var showingError: Bool = false
    var showingSuccess: Bool = false
    var successMessage: String = ""
    var showingCamera = false
    var capturedImage: UIImage?
    var showingLabelInput = false
    var newLabel = ""
    var showingBatchCapture = false
    
    // Computed properties for reactive button states
    internal var captureButtonEnabled: Bool {
        !selectedLabel.isEmpty && !isTraining
    }
    
    internal var trainButtonEnabled: Bool {
        availableLabels.count >= 2 && !isTraining
    }
    
    internal var statisticsCardViewModel: StatisticCardViewModel = {
        StatisticCardViewModel(title: "Training Statistics", statistics: [StatisticItem(value: "0", label: "Total Images", alignment: .leading),
                                                                          StatisticItem(value: "0", label: "Categories", alignment: .trailing)])
    }()
    
    // MARK: - Dependencies
    let trainingDataService: TrainingDataServiceProtocol
    private let mlModelService: MLModelServiceProtocol
    private let modelManager: ModelManagerProtocol
    
    // MARK: - Initialization
    init(
        trainingDataService: TrainingDataServiceProtocol,
        mlModelService: MLModelServiceProtocol,
        modelManager: ModelManagerProtocol
    ) {
        self.trainingDataService = trainingDataService
        self.mlModelService = mlModelService
        self.modelManager = modelManager
        
        Task {
            await loadTrainingData()
            await loadSelectedModel()
        }
    }
    
    // MARK: - Public Methods
    func saveTrainingImage(_ image: UIImage, label: String) {
        Task {
            await saveTrainingImageInBackground(image, label: label)
        }
    }
    
    nonisolated func saveTrainingImageAsync(_ image: UIImage, label: String) async throws {
        let modelName = await MainActor.run { selectedModelName }
        
        guard let modelName = modelName else {
            await MainActor.run {
                errorMessage = "No model selected"
                showingError = true
            }
            throw TrainingDataError.imageNotFound
        }
        
        // Convert UIImage to VinceMLImage for platform-agnostic processing
        let vinceMLImage: VinceMLImage = image
        try await trainingDataService.saveTrainingImage(vinceMLImage, with: label, for: modelName)
        
        await refreshData()
    }
    
    func deleteTrainingImage(id: UUID) {
        guard let modelName = selectedModelName else {
            showError("No model selected")
            return
        }
        
        Task {
            await deleteImageInBackground(id: id, modelName: modelName)
        }
    }
    
    func deleteAllImagesForLabel(_ label: String) {
        guard let modelName = selectedModelName else {
            showError("No model selected")
            return
        }
        
        Task {
            await deleteAllImagesForLabelInBackground(label, modelName: modelName)
        }
    }
    
    func trainModel() {
        guard availableLabels.count >= 2 else {
            showError("Need at least 2 different labels to train a model")
            return
        }
        
        guard trainingImages.count >= 10 else {
            showError("Need at least 10 training images total")
            return
        }
        
        Task {
            await trainModelInBackground()
        }
    }
    
    func refreshData() {
        Task {
            await loadTrainingData()
            await loadSelectedModel()
            await autoSelectFirstLabelIfNeeded()
        }
    }
    
    // MARK: - UI Interaction Methods
    func showCamera() {
        showingCamera = true
    }
    
    func showBatchCapture() {
        showingBatchCapture = true
    }
    
    func showLabelInput() {
        showingLabelInput = true
    }
    
    func handleCapturedImage(_ image: UIImage?) {
        guard let image = image else { return }
        saveTrainingImage(image, label: selectedLabel)
        capturedImage = nil
    }
    
    func addNewLabel(_ label: String) {
        guard !label.isEmpty else { return }
        selectedLabel = label
        showingLabelInput = false
        newLabel = ""
        
        // Save the new label to persistent storage
        Task {
            do {
                if let modelName = selectedModelName {
                    try await trainingDataService.addLabel(label, for: modelName)
                    refreshData() // Refresh to update the label collection
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add label: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    func cancelLabelInput() {
        showingLabelInput = false
        newLabel = ""
    }
    
    func dismissBatchCapture() {
        showingBatchCapture = false
    }
    
    func dismissError() {
        showingError = false
        errorMessage = nil
    }
    
    func dismissSuccess() {
        showingSuccess = false
        successMessage = ""
    }
    
    // MARK: - Private Methods
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        showingSuccess = true
    }
    
    // MARK: - Background Operations
    nonisolated private func autoSelectFirstLabelIfNeeded() async {
        await MainActor.run {
            // Auto-select first label if none is selected and labels are available
            if selectedLabel.isEmpty && !availableLabels.isEmpty {
                selectedLabel = availableLabels.sorted().first ?? ""
            }
        }
    }
    
    nonisolated private func saveTrainingImageInBackground(_ image: UIImage, label: String) async {
        do {
            try await saveTrainingImageAsync(image, label: label)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save training image: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    nonisolated private func loadSelectedModel() async {
        let selectedName = await modelManager.getSelectedModelName()
        let previousModelName = await MainActor.run { selectedModelName }
        
        await MainActor.run {
            selectedModelName = selectedName
        }
        
        // If the selected model changed, reload training data
        if selectedName != previousModelName {
            await loadTrainingData()
        }
    }
    
    nonisolated private func saveImageInBackground(_ image: UIImage, label: String, modelName: String) async {
        do {
            try await trainingDataService.saveTrainingImage(image, with: label, for: modelName)
            await MainActor.run {
                selectedLabel = label
            }
            await loadTrainingData()
        } catch {
            await MainActor.run {
                showError("Failed to save image: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated private func deleteImageInBackground(id: UUID, modelName: String) async {
        do {
            try await trainingDataService.deleteTrainingImage(id: id, for: modelName)
            await loadTrainingData()
        } catch {
            await MainActor.run {
                showError("Failed to delete image: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated private func deleteAllImagesForLabelInBackground(_ label: String, modelName: String) async {
        do {
            try await trainingDataService.deleteAllImagesForLabel(label, for: modelName)
            await MainActor.run {
                if selectedLabel == label {
                    selectedLabel = ""
                }
            }
            await loadTrainingData()
        } catch {
            await MainActor.run {
                showError("Failed to delete images: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated private func trainModelInBackground() async {
        await MainActor.run {
            isTraining = true
            trainingProgress = 0.0
        }
        
        do {
            // Get the currently selected model name
            guard let selectedModelName = await modelManager.getSelectedModelName() else {
                await MainActor.run {
                    isTraining = false
                    trainingProgress = 0.0
                    showError("No model selected. Please select a model from the Models tab.")
                }
                return
            }
            
            let trainingDataURL = await trainingDataService.getTrainingImagesURL(for: selectedModelName)
            
            await MainActor.run {
                trainingProgress = 0.2
            }
            
            await MainActor.run {
                trainingProgress = 0.3
            }
            
            // Get the model training URL where we want to save the .mlmodel file
            let modelTrainingURL = await modelManager.getModelTrainingURL(name: selectedModelName)
            
            // Train and save the model directly to the model directory
            let _ = try await mlModelService.trainAndSaveModel(from: trainingDataURL, to: modelTrainingURL)
            
            await MainActor.run {
                trainingProgress = 0.8
            }
            
            // Now compile and save the trained model as .mlmodelc
            try await modelManager.saveTrainedModel(from: modelTrainingURL, name: selectedModelName)
            
            await MainActor.run {
                trainingProgress = 1.0
                isTraining = false
                showSuccess("Model '\(selectedModelName)' trained successfully!")
            }
            
        } catch {
            await MainActor.run {
                isTraining = false
                trainingProgress = 0.0
                showError("Training failed: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated private func loadTrainingData() async {
        // Get the currently selected model name
        guard let selectedModelName = await modelManager.getSelectedModelName() else {
            await MainActor.run {
                trainingImages = []
                availableLabels = []
                statisticsCardViewModel.updateStatistics([
                    StatisticItem(value: "0", label: "Total Images", alignment: .leading),
                    StatisticItem(value: "0", label: "Categories", alignment: .trailing)
                ])
            }
            return
        }
        
        do {
            let images = try await trainingDataService.getTrainingImages(for: selectedModelName)
            let labels = try await trainingDataService.getAllLabels(for: selectedModelName)
            
            await MainActor.run {
                trainingImages = images
                availableLabels = labels
                statisticsCardViewModel.updateStatistics([
                    StatisticItem(value: "\(trainingImages.count)", label: "Total Images", alignment: .leading),
                    StatisticItem(value: "\(availableLabels.count)", label: "Categories", alignment: .trailing)
                ])
            }
        } catch {
            await MainActor.run {
                showError("Failed to load training data: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Training Errors
enum TrainingError: Error, LocalizedError {
    case noModelSelected
    case invalidLabel
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noModelSelected:
            return "No model selected for training"
        case .invalidLabel:
            return "Invalid label provided"
        case .saveFailed(let message):
            return "Failed to save training data: \(message)"
        }
    }
}
