//
//  LabelChipViewModel.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation

/// ViewModel for LabelChip component that manages selectable label behavior
/// 
/// Use this component for tag-like selection interfaces, category filters,
/// or any scenario where users need to select from predefined options.
///
/// **Usage:**
/// ```swift
/// let chipVM = LabelChipViewModel(
///     label: "Aviator",
///     isSelected: true,
///     chipType: .selectable,
///     onTap: { selectLabel("Aviator") }
/// )
/// ```
@MainActor
@Observable
class LabelChipViewModel {
    /// The text displayed on the chip
    var label: String
    
    /// Whether this chip is currently selected
    var isSelected: Bool
    
    /// The type of chip (affects appearance and behavior)
    var chipType: ChipType
    
    /// Action to perform when the chip is tapped
    let onTap: () -> Void
    
    /// Initialize a new label chip
    /// - Parameters:
    ///   - label: Text to display on the chip
    ///   - isSelected: Initial selection state
    ///   - chipType: Type of chip (affects styling and behavior)
    ///   - onTap: Action to perform when tapped
    init(
        label: String,
        isSelected: Bool = false,
        chipType: ChipType = .selectable,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.isSelected = isSelected
        self.chipType = chipType
        self.onTap = onTap
    }
    
    /// Execute the tap action without toggling internal state
    /// Selection state should be managed externally for single-selection behavior
    func toggle() {
        onTap()
    }
    
    /// Programmatically set the selection state
    /// - Parameter selected: New selection state
    func setSelected(_ selected: Bool) {
        isSelected = selected
    }
}

/// Types of chips that determine appearance and behavior
enum ChipType {
    /// Standard selectable chip - toggles selection state
    case selectable
    /// Add new chip - typically shows a plus icon for adding new items
    case addNew
    /// Removable chip - shows an X icon for removing items
    case removable
}
