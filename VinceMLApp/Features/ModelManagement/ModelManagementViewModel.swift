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
    var showingCreateModel: Bool = false
    var newModelName: String = ""
    
    // MARK: - Loading State
    var loadingState = LoadingState.idle
    
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
        loadingState = .success("Model '\(name)' selected for training")
        
        // Auto-dismiss success after 2 seconds
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            loadingState = .idle
        }
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
    
    func clearLoadingState() {
        loadingState = .idle
    }
    
    // MARK: - Private Methods
    private func showError(_ message: String) {
        loadingState = .failure(message)
    }
    
    private func showSuccess(_ message: String) {
        loadingState = .success(message)
        
        // Auto-dismiss success after 2 seconds
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            loadingState = .idle
        }
    }
    
    // MARK: - Background Operations
    nonisolated private func loadData() async {
        await MainActor.run {
            loadingState = .loading()
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
            loadingState = .idle
        }
    }
    
    nonisolated private func createModelInBackground(name: String) async {
        await MainActor.run {
            loadingState = .loading()
        }
        
        do {
            try await modelManager.createEmptyModel(name: name)
            await modelManager.setSelectedModel(name: name)
            
            await MainActor.run {
                selectedModel = name
                loadingState = .success("Model '\(name)' created successfully!")
                
                // Auto-dismiss success after 2 seconds
                Task {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    loadingState = .idle
                }
            }
            
            await loadData()
        } catch {
            await MainActor.run {
                loadingState = .failure("Failed to create model: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated private func deleteModelInBackground(name: String) async {
        await MainActor.run {
            loadingState = .loading()
        }
        
        do {
            try await modelManager.deleteModel(name: name)
            
            await MainActor.run {
                if selectedModel == name {
                    selectedModel = nil
                }
                loadingState = .success("Model '\(name)' deleted successfully!")
                
                // Auto-dismiss success after 2 seconds
                Task {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    loadingState = .idle
                }
            }
            
            await loadData()
        } catch {
            await MainActor.run {
                loadingState = .failure("Failed to delete model: \(error.localizedDescription)")
            }
        }
    }
}
