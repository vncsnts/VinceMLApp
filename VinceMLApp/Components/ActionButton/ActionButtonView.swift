//
//  ActionButtonView.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import SwiftUI

/// A standardized button component with multiple styles and states
/// 
/// Provides consistent button behavior across the app with built-in loading states,
/// enable/disable functionality, and multiple visual styles. Automatically handles
/// styling based on button state.
///
/// **Features:**
/// - Multiple predefined styles (primary, secondary, success, warning, danger)
/// - Loading state with spinner animation
/// - Enable/disable functionality with visual feedback
/// - Icon support with SF Symbols
/// - Consistent sizing and responsive design
///
/// **Usage:**
/// ```swift
/// ActionButtonView(
///     viewModel: ActionButtonViewModel(
///         title: "Save Data",
///         icon: "square.and.arrow.down",
///         style: .primary,
///         action: { performSave() }
///     )
/// )
/// ```
///
/// **State Management:**
/// ```swift
/// // Update button state
/// buttonViewModel.setLoading(true) // Shows spinner
/// buttonViewModel.setEnabled(false) // Disables button
/// ```
struct ActionButtonView: View {
    @State private var viewModel: ActionButtonViewModel
    private let enabledBinding: Binding<Bool>?
    
    /// Initialize with an ActionButtonViewModel
    /// - Parameter viewModel: The view model managing button state and behavior
    init(viewModel: ActionButtonViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
        self.enabledBinding = nil
    }
    
    /// Initialize with direct parameters (creates internal ViewModel)
    /// - Parameters:
    ///   - title: Button title text
    ///   - icon: Optional SF Symbol name for button icon
    ///   - isEnabled: Whether the button is enabled (default: true)
    ///   - style: Button style determining appearance
    ///   - action: Action to perform when button is tapped
    init(
        title: String,
        icon: String? = nil,
        isEnabled: Bool = true,
        style: ActionButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self._viewModel = State(wrappedValue: ActionButtonViewModel(
            title: title,
            icon: icon,
            isEnabled: isEnabled,
            style: style,
            action: action
        ))
        self.enabledBinding = nil
    }
    
    /// Initialize with reactive enabled binding (creates internal ViewModel)
    /// - Parameters:
    ///   - title: Button title text
    ///   - icon: Optional SF Symbol name for button icon
    ///   - isEnabled: Binding to reactive enabled state
    ///   - style: Button style determining appearance
    ///   - action: Action to perform when button is tapped
    init(
        title: String,
        icon: String? = nil,
        isEnabled: Binding<Bool>,
        style: ActionButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self._viewModel = State(wrappedValue: ActionButtonViewModel(
            title: title,
            icon: icon,
            isEnabled: true, // Will be overridden by binding
            style: style,
            action: action
        ))
        self.enabledBinding = isEnabled
    }
    
    var body: some View {
        let isEnabled = enabledBinding?.wrappedValue ?? viewModel.isEnabled
        
        Button(action: {
            viewModel.execute()
        }) {
            HStack {
                // Loading spinner (shown when loading)
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                // Icon (shown when not loading and icon exists)
                if let icon = viewModel.icon, !viewModel.isLoading {
                    Image(systemName: icon)
                        .font(.system(size: viewModel.style == .primary ? 40 : 16))
                }
                
                // Button text (changes to "Loading..." when loading)
                Text(viewModel.isLoading ? "Loading..." : viewModel.title)
                    .font(viewModel.style == .primary ? .headline : .body)
            }
            .foregroundColor(isEnabled && !viewModel.isLoading ? foregroundColor : Color.gray)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled && !viewModel.isLoading ? backgroundColor : Color.gray.opacity(0.3))
            .cornerRadius(10)
        }
        .disabled(!isEnabled || viewModel.isLoading)
    }
    
    /// Computed background color based on button style
    private var backgroundColor: Color {
        switch viewModel.style {
        case .primary:
            return Color.blue
        case .secondary:
            return Color.gray.opacity(0.2)
        case .success:
            return Color.green
        case .warning:
            return Color.orange
        case .danger:
            return Color.red
        }
    }
    
    /// Computed foreground color based on button style
    private var foregroundColor: Color {
        switch viewModel.style {
        case .primary, .success, .warning, .danger:
            return .white
        case .secondary:
            return .primary
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Using direct initialization (internal ViewModel)
        ActionButtonView(
            title: "Start Training",
            icon: "play.fill",
            style: .success,
            action: {}
        )
        
        ActionButtonView(
            title: "Capture Image",
            icon: "camera.fill",
            action: {}
        )
        
        // Using ViewModel injection for complex state management
        ActionButtonView(
            viewModel: ActionButtonViewModel(
                title: "Advanced Action",
                icon: "gear",
                isEnabled: false,
                style: .danger,
                action: {}
            )
        )
    }
    .padding()
}
