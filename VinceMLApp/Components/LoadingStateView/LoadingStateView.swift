//
//  LoadingStateView.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import SwiftUI

/// A reusable view component for displaying loading states
/// 
/// Provides both indeterminate and determinate progress indicators
/// with customizable messages for various loading scenarios.
///
/// **Features:**
/// - Circular progress indicator for indeterminate loading
/// - Linear progress bar with percentage for determinate loading
/// - Dynamic message updates during loading operations
/// - Consistent styling and spacing
/// - Responsive layout that adapts to content
///
/// **Usage:**
/// ```swift
/// // Simple indeterminate loading
/// LoadingStateView(
///     viewModel: LoadingStateViewModel(
///         message: "Loading training data..."
///     )
/// )
///
/// // Progress-based loading with percentage
/// LoadingStateView(
///     viewModel: LoadingStateViewModel(
///         message: "Training model...",
///         progress: 0.75,
///         showProgress: true
///     )
/// )
/// ```
///
/// **Design Guidelines:**
/// - Use indeterminate loading for unknown duration operations
/// - Use determinate loading when progress can be measured
/// - Keep messages informative but concise
/// - Update messages to reflect current operation phase
struct LoadingStateView: View {
    @State private var viewModel: LoadingStateViewModel
    
    /// Initialize with a LoadingStateViewModel
    /// - Parameter viewModel: The view model managing loading state and progress
    init(viewModel: LoadingStateViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    /// Initialize with direct parameters (creates internal ViewModel)
    /// - Parameters:
    ///   - message: Loading message to display (default: "Loading...")
    ///   - progress: Optional progress value (0.0 to 1.0)
    ///   - showProgress: Whether to display progress bar (default: false)
    init(
        message: String = "Loading...",
        progress: Double? = nil,
        showProgress: Bool = false
    ) {
        self._viewModel = State(wrappedValue: LoadingStateViewModel(
            message: message,
            progress: progress,
            showProgress: showProgress
        ))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress indicator
            if viewModel.showProgress, let progress = viewModel.progress {
                // Determinate progress with linear bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: 200)
                
                // Percentage display
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Indeterminate progress with circular indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
            }
            
            // Loading message
            Text(viewModel.message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    VStack(spacing: 40) {
        // Using direct initialization (internal ViewModel)
        LoadingStateView(
            message: "Loading models..."
        )
        
        LoadingStateView(
            message: "Training model...",
            progress: 0.65,
            showProgress: true
        )
        
        // Using ViewModel injection for dynamic updates
        LoadingStateView(
            viewModel: LoadingStateViewModel(
                message: "Processing images...",
                progress: 0.3,
                showProgress: true
            )
        )
    }
}
