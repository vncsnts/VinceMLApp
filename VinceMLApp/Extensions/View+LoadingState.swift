import SwiftUI

// MARK: - Simple Loading State
/**
 A simple loading state struct that represents the current status of an async operation.
 
 ## Usage in ViewModel:
 ```swift
 @MainActor
 class MyViewModel: ObservableObject {
     @Published var loadingState = LoadingState.idle
     
     func performAction() async {
         loadingState = .loading
         
         do {
             // Your async operation here
             let result = try await someAsyncOperation()
             loadingState = .success("Operation completed!")
         } catch {
             loadingState = .failure(error.localizedDescription)
         }
     }
 }
 ```
 
 ## Usage in View:
 ```swift
 struct MyView: View {
     @StateObject private var viewModel = MyViewModel()
     
     var body: some View {
         VStack {
             // Your content here
         }
         .loadingState(viewModel.loadingState) {
             // Optional retry action
             Task { await viewModel.performAction() }
         }
     }
 }
 ```
 */
struct LoadingState {
    /// The current status of the loading operation
    enum Status {
        /// No operation in progress
        case idle
        /// Operation is currently silently running
        case silentLoading
        /// Operation is currently running
        case loading(message: String? = nil)
        /// Operation completed successfully with optional message
        case success(message: String? = nil)
        /// Operation failed with error message
        case failure(message: String)
    }
    
    let status: Status
    
    // MARK: - Static Constructors
    /// Creates an idle state (no operation in progress)
    static let idle = LoadingState(status: .idle)
    
    /// Creates a loading state with optional message
    /// - Parameter message: Optional loading message to display
    static func loading(_ message: String? = nil) -> LoadingState {
        LoadingState(status: .loading(message: message))
    }
    
    /// Creates a silent loading state (operation in progress)
    static let silentLoading = LoadingState(status: .silentLoading)
    
    /// Creates a success state with optional message
    /// - Parameter message: Optional success message to display
    static func success(_ message: String? = nil) -> LoadingState {
        LoadingState(status: .success(message: message))
    }
    
    /// Creates a failure state with error message
    /// - Parameter message: Error message to display
    static func failure(_ message: String) -> LoadingState {
        LoadingState(status: .failure(message: message))
    }
    
    // MARK: - Computed Properties
    /// Returns true if the operation is currently loading
    var isLoading: Bool {
        if case .loading = status { return true }
        return false
    }
    
    /// Returns true if the operation is currently silent loading
    var isSilentLoading: Bool {
        if case .silentLoading = status { return true }
        return false
    }
    
    /// Returns true if the operation completed successfully
    var isSuccess: Bool {
        if case .success = status { return true }
        return false
    }
    
    /// Returns true if the operation failed
    var isFailure: Bool {
        if case .failure = status { return true }
        return false
    }
    
    /// Returns the error message if the operation failed
    var errorMessage: String? {
        if case .failure(let message) = status { return message }
        return nil
    }
    
    /// Returns the success message if the operation succeeded
    var successMessage: String? {
        if case .success(let message) = status { return message }
        return nil
    }
    
    /// Returns the loading message if the operation is loading
    var loadingMessage: String {
        if case .loading(let message) = status { return message ?? "Loading..." }
        return "Loading..."
    }
}

// MARK: - View Modifier
/**
 A view modifier that displays loading, success, and error overlays based on the LoadingState.
 
 ## Features:
 - Automatic loading overlay with progress indicator
 - Error overlay with retry functionality
 - Success overlay with optional message
 - Disables content interaction during loading
 */
struct LoadingStateModifier: ViewModifier {
    let loadingState: LoadingState
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(loadingState.isLoading)
            
            if loadingState.isLoading {
                LoadingOverlay(message: loadingState.loadingMessage)
            }
            
            if loadingState.isFailure, let errorMessage = loadingState.errorMessage {
                ErrorOverlay(message: errorMessage, onRetry: onRetry, onDismiss: onDismiss)
            }
            
            if loadingState.isSuccess, let successMessage = loadingState.successMessage {
                SuccessOverlay(message: successMessage)
            }
        }
    }
}

// MARK: - Overlay Views
/// Loading overlay that displays a spinner with "Loading..." text
private struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.body)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
    }
}

/// Error overlay that displays error message with optional retry button
private struct ErrorOverlay: View {
    let message: String
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss?()
                }
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.headline)
                
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    if let onRetry = onRetry {
                        Button("Try Again") {
                            onRetry()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Dismiss") {
                        onDismiss?()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
            .padding(.horizontal, 32)
        }
    }
}

/// Success overlay that displays success message with checkmark
private struct SuccessOverlay: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.green)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - View Extension
extension View {
    /**
     Applies loading state overlay to any view.
     
     - Parameters:
        - state: The LoadingState to observe
        - onRetry: Optional closure called when user taps "Try Again" button in error overlay
        - onDismiss: Optional closure called when user taps "Dismiss" button in error overlay
     
     - Returns: A view modified with loading state overlays
     
     ## Usage:
     ```swift
     VStack {
         // Your content
     }
     .loadingState(viewModel.loadingState, 
                   onRetry: { Task { await viewModel.retryOperation() } },
                   onDismiss: { viewModel.clearState() })
     ```
     
     ## Features:
     - Shows loading spinner during `.loading` state
     - Shows error overlay with retry button during `.failure` state
     - Shows success overlay during `.success` state (if message provided)
     - Disables user interaction with content during loading
     */
    func loadingState(_ state: LoadingState, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(LoadingStateModifier(loadingState: state, onRetry: onRetry, onDismiss: onDismiss))
    }
}
