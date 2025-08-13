//
//  ModelManagementViewModel.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation
import CoreML
import VinceML

/// ViewModel for managing machine learning model lifecycle operations
///
/// Provides comprehensive model management functionality including:
/// - Model creation, deletion, and selection
/// - Model listing and availability tracking
/// - Model state management and synchronization
/// - Error handling for model operations
///
/// **Core Responsibilities:**
/// - Maintains current model selection state
/// - Provides interface for model CRUD operations
/// - Handles async model operations with loading states
/// - Coordinates with ModelManager for persistent operations
///
/// **UI Integration:**
/// - Observable properties for real-time UI updates
/// - Loading states for async operations
/// - Error handling with user-friendly messages
/// - Model selection persistence across app sessions
///
/// **Model Lifecycle:**
/// 1. Create empty model structure
/// 2. Populate with training data (via TrainingViewModel)
/// 3. Train model (via TrainingViewModel)
/// 4. Select for inference (via ClassificationViewModel)
/// 5. Delete when no longer needed
@MainActor
@Observable
class ModelManagementViewModel {
    
    // MARK: - Published Properties
    var availableModels: [String] = []
    var selectedModel: String?
    var isLoading: Bool = false
    var isCreatingModel: Bool = false
    var errorMessage: String?
    var showingError: Bool = false
    var showingSuccess: Bool = false
    var successMessage: String = ""
    var showingCreateModel: Bool = false
    var newModelName: String = ""
    
    // MARK: - Dependencies
    private let modelManager: ModelManagerProtocol
    
    // MARK: - Initialization
    init(modelManager: ModelManagerProtocol) {
        self.modelManager = modelManager
        
        Task {
            await loadData()
        }
    }
    
    // MARK: - Public Methods
    func selectModel(name: String) {
        selectedModel = name
        Task {
            await modelManager.setSelectedModel(name: name)
        }
        showSuccess("Model '\(name)' selected for training")
    }
    
    func createModel(name: String) {
        Task {
            await createModelInBackground(name: name)
        }
    }
    
    func deleteModel(name: String) {
        Task {
            await deleteModelInBackground(name: name)
        }
    }
    
    func refreshData() {
        Task {
            await loadData()
        }
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
    nonisolated private func loadData() async {
        await MainActor.run {
            isLoading = true
        }
        
        let models = await modelManager.getAvailableModels()
        let selected = await modelManager.getSelectedModelName()
        
        await MainActor.run {
            availableModels = models
            selectedModel = selected
            // Set the first model as selected if none is selected
            if selectedModel == nil && !models.isEmpty {
                selectedModel = models.first
                if let firstModel = models.first {
                    Task {
                        await modelManager.setSelectedModel(name: firstModel)
                    }
                }
            }
            isLoading = false
        }
    }
    
    nonisolated private func createModelInBackground(name: String) async {
        await MainActor.run {
            isCreatingModel = true
        }
        
        do {
            try await modelManager.createEmptyModel(name: name)
            await modelManager.setSelectedModel(name: name)
            
            await MainActor.run {
                selectedModel = name
                isCreatingModel = false
                showSuccess("Model '\(name)' created successfully!")
            }
            
            await loadData()
        } catch {
            await MainActor.run {
                isCreatingModel = false
                showError("Failed to create model: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated private func deleteModelInBackground(name: String) async {
        do {
            try await modelManager.deleteModel(name: name)
            
            await MainActor.run {
                if selectedModel == name {
                    selectedModel = nil
                }
                showSuccess("Model '\(name)' deleted successfully!")
            }
            
            await loadData()
        } catch {
            await MainActor.run {
                showError("Failed to delete model: \(error.localizedDescription)")
            }
        }
    }
}
