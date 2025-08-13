//
//  LabelChipView.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import SwiftUI

/// A chip component for selectable labels and tags
/// 
/// Provides pill-shaped buttons for selection interfaces, tag systems,
/// and category filters. Supports different types for various use cases.
///
/// **Features:**
/// - Multiple chip types (selectable, addNew, removable)
/// - Selection state with visual feedback
/// - Icon support for special chip types
/// - Consistent pill-shaped styling
/// - Color-coded based on chip type and state
///
/// **Usage:**
/// ```swift
/// LabelChipView(
///     viewModel: LabelChipViewModel(
///         label: "Machine Learning",
///         isSelected: true,
///         chipType: .selectable,
///         onTap: { selectCategory("Machine Learning") }
///     )
/// )
/// ```
struct LabelChipView: View {
    @Bindable private var viewModel: LabelChipViewModel
    
    /// Initialize with a LabelChipViewModel
    /// - Parameter viewModel: The view model managing chip state and behavior
    init(viewModel: LabelChipViewModel) {
        self.viewModel = viewModel
    }
    
    /// Initialize with direct parameters (creates internal ViewModel)
    /// - Parameters:
    ///   - label: Chip label text
    ///   - isSelected: Whether the chip is selected (default: false)
    ///   - chipType: Type of chip determining appearance and behavior
    ///   - onTap: Action to perform when chip is tapped
    init(
        label: String,
        isSelected: Bool = false,
        chipType: ChipType = .selectable,
        onTap: @escaping () -> Void = {}
    ) {
        self.viewModel = LabelChipViewModel(
            label: label,
            isSelected: isSelected,
            chipType: chipType,
            onTap: onTap
        )
    }
    
    var body: some View {
        Button(action: {
            viewModel.toggle()
        }) {
            HStack(spacing: 6) {
                // Content based on chip type
                switch viewModel.chipType {
                case .addNew:
                    Image(systemName: "plus")
                        .font(.caption)
                case .removable:
                    Text(viewModel.label)
                    Image(systemName: "xmark")
                        .font(.caption)
                case .selectable:
                    Text(viewModel.label)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(20) // Pill shape
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Background color based on chip type and selection state
    private var backgroundColor: Color {
        switch viewModel.chipType {
        case .selectable:
            return viewModel.isSelected ? Color.blue : Color.gray.opacity(0.2)
        case .addNew:
            return Color.green.opacity(0.2)
        case .removable:
            return Color.red.opacity(0.2)
        }
    }
    
    /// Foreground color based on chip type and selection state
    private var foregroundColor: Color {
        switch viewModel.chipType {
        case .selectable:
            return viewModel.isSelected ? .white : .primary
        case .addNew:
            return .green
        case .removable:
            return .red
        }
    }
}

/// A collection view for managing multiple label chips
/// 
/// Provides a horizontal scrolling collection of chips with built-in
/// selection management and add new functionality.
///
/// **Usage:**
/// ```swift
/// LabelChipCollection(
///     labels: ["Aviator", "Wayfarer", "Round"],
///     selectedLabel: $selectedCategory,
///     onAddNew: { showAddCategoryDialog() },
///     onRemove: { category in removeCategory(category) }
/// )
/// ```
struct LabelChipCollection: View {
    
    enum LabelChipCollectionType {
        case singleSelect
        case multiSelect
    }
    /// Array of label strings to display as chips
    let labels: [String]
    
    /// Binding to the currently selected label
    @Binding var selectedLabel: String
    
    /// Type of Label Collection
    let collectionType: LabelChipCollectionType
    
    /// Action to perform when add new chip is tapped
    let onAddNew: () -> Void
    
    /// Initialize a chip collection
    /// - Parameters:
    ///   - labels: Array of label strings
    ///   - selectedLabel: Binding to selected label
    init(
        labels: [String],
        selectedLabel: Binding<String>,
        collectionType: LabelChipCollectionType = .singleSelect,
        onAddNew: @escaping () -> Void
    ) {
        self.labels = labels
        self._selectedLabel = selectedLabel
        self.collectionType = collectionType
        self.onAddNew = onAddNew
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                // Label chips
                ForEach(labels, id: \.self) { label in
                    LabelChipView(
                        viewModel: LabelChipViewModel(
                            label: label,
                            isSelected: selectedLabel == label,
                            chipType: .selectable,
                            onTap: {
                                selectedLabel = label
                            }
                        )
                    )
                }
                
                // Add new chip
                LabelChipView(
                    viewModel: LabelChipViewModel(
                        label: "",
                        chipType: .addNew,
                        onTap: onAddNew
                    )
                )
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedLabel = "Aviator"
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Selected: \(selectedLabel)")
                    .font(.headline)
                
                // Individual chips
                VStack(spacing: 10) {
                    LabelChipView(
                        label: "Aviator",
                        isSelected: true,
                        chipType: .selectable
                    )
                    
                    LabelChipView(
                        label: "Add New",
                        chipType: .addNew
                    )
                    
                    LabelChipView(
                        viewModel: LabelChipViewModel(
                            label: "Removable",
                            chipType: .removable,
                            onTap: { 
                                // Handle chip removal
                                // In real implementation, this would remove the chip from a collection
                            }
                        )
                    )
                }
                
                // Chip collection with single selection
                LabelChipCollection(
                    labels: ["Aviator", "Wayfarer", "Round", "Cat-eye"],
                    selectedLabel: $selectedLabel,
                    onAddNew: {
                        // Handle adding new label
                        // In real implementation, this would show a dialog or sheet
                        // to input new label name and add it to the collection
                    }
                )
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
