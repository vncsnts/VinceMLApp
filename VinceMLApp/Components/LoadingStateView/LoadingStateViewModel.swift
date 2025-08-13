//
//  LoadingStateViewModel.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation

/// ViewModel for managing loading state display and progress tracking
/// 
/// Controls the presentation of loading indicators with optional progress
/// tracking and dynamic message updates for long-running operations.
///
/// **Responsibilities:**
/// - Manages loading message and progress state
/// - Provides progress updates for trackable operations
/// - Maintains published properties for reactive UI updates
/// - Supports both indeterminate and determinate progress
///
/// **Usage Patterns:**
/// ```swift
/// // Simple indeterminate loading
/// let simpleLoading = LoadingStateViewModel(
///     message: "Loading training data..."
/// )
///
/// // Progress-based loading for model training
/// let trainingProgress = LoadingStateViewModel(
///     message: "Training model...",
///     progress: 0.0,
///     showProgress: true
/// )
///
/// // Update progress during operation
/// trainingProgress.updateProgress(0.75, message: "Finalizing model...")
/// ```
///
/// **Common Use Cases:**
/// - Model training with progress tracking
/// - Data loading operations
/// - File upload/download progress
/// - Image processing operations
/// - Network request handling
/// - Long-running computations
@MainActor
@Observable
class LoadingStateViewModel {
    /// Current loading message displayed to the user
    var message: String
    
    /// Optional progress value between 0.0 and 1.0
    var progress: Double?
    
    /// Whether to show the progress bar component
    var showProgress: Bool
    
    /// Initialize a LoadingStateViewModel
    /// - Parameters:
    ///   - message: Initial loading message (default: "Loading...")
    ///   - progress: Optional initial progress value (0.0 to 1.0)
    ///   - showProgress: Whether to display progress bar (default: false)
    init(
        message: String = "Loading...",
        progress: Double? = nil,
        showProgress: Bool = false
    ) {
        self.message = message
        self.progress = progress
        self.showProgress = showProgress
    }
    
    /// Update the progress value and optionally the message
    /// 
    /// Automatically enables progress display when called. Use this method
    /// to provide feedback during long-running operations.
    ///
    /// - Parameters:
    ///   - newProgress: Progress value between 0.0 and 1.0
    ///   - message: Optional new message to display
    func updateProgress(_ newProgress: Double, message: String? = nil) {
        progress = newProgress
        showProgress = true
        if let message = message {
            self.message = message
        }
    }
    
    /// Update only the loading message
    /// 
    /// Use this to provide status updates without changing progress.
    /// Useful for multi-step operations where you want to inform users
    /// of the current step without specific progress metrics.
    ///
    /// - Parameter newMessage: New message to display
    func updateMessage(_ newMessage: String) {
        message = newMessage
    }
}
