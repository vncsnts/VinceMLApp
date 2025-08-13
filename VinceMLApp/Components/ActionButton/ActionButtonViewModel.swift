//
//  ActionButtonViewModel.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation

/// ViewModel for ActionButton component that manages button state and behavior
/// 
/// Provides standardized button functionality with loading states, enable/disable,
/// multiple styles, and icon support. Handles all button logic and state management.
///
/// **Usage:**
/// ```swift
/// let saveButton = ActionButtonViewModel(
///     title: "Save Changes",
///     icon: "square.and.arrow.down",
///     style: .primary,
///     action: { saveData() }
/// )
/// 
/// // Update state based on conditions
/// saveButton.setEnabled(isFormValid)
/// saveButton.setLoading(isSaving)
/// ```
@MainActor
@Observable
final class ActionButtonViewModel {
    /// The text displayed on the button
    var title: String
    
    /// Optional SF Symbol icon name to display
    var icon: String?
    
    /// Whether the button is enabled and responsive to taps
    var isEnabled: Bool
    
    /// Whether the button is in loading state (shows spinner)
    var isLoading: Bool
    
    /// The visual style of the button
    var style: ActionButtonStyle
    
    /// The action to perform when the button is tapped
    let action: () -> Void
    
    /// Initialize a new ActionButton
    /// - Parameters:
    ///   - title: Button text (keep concise, 1-3 words)
    ///   - icon: Optional SF Symbol name
    ///   - isEnabled: Initial enabled state
    ///   - isLoading: Initial loading state
    ///   - style: Visual style (see ActionButtonStyle)
    ///   - action: Closure to execute on button tap
    init(
        title: String,
        icon: String? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        style: ActionButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.style = style
        self.action = action
    }
    
    /// Programmatically execute the button's action
    /// Use this when you need to trigger the button action from code
    func execute() {
        action()
    }
    
    /// Update the loading state of the button
    /// When loading is true, button shows spinner and becomes disabled
    /// - Parameter loading: New loading state
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    /// Update the enabled state of the button
    /// Disabled buttons are grayed out and non-interactive
    /// - Parameter enabled: New enabled state
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}

/// Visual styles available for ActionButton
/// Each style has specific colors and use cases
enum ActionButtonStyle {
    /// Blue background, white text - Use for primary actions
    case primary
    /// Gray background, primary text - Use for secondary actions
    case secondary
    /// Green background, white text - Use for positive actions (save, complete)
    case success
    /// Orange background, white text - Use for cautionary actions
    case warning
    /// Red background, white text - Use for destructive actions (delete, cancel)
    case danger
}
