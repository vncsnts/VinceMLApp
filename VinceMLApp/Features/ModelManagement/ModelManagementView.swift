//
//  ModelManagementView.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import SwiftUI

struct ModelManagementView: View {
    @State private var viewModel: ModelManagementViewModel
    @State private var showingDeleteAlert = false
    @State private var modelToDelete: String = ""
    
    init(viewModel: ModelManagementViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.availableModels.isEmpty && !viewModel.loadingState.isLoading {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Models")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Create your first model to get started with training")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            viewModel.showingCreateModel = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Create Model")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.availableModels.isEmpty {
                    // Models list
                    ScrollView {
                        ForEach(viewModel.availableModels, id: \.self) { modelName in
                            ModelRow(
                                modelName: modelName,
                                isSelected: viewModel.selectedModel == modelName,
                                onSelect: {
                                    viewModel.selectModel(name: modelName)
                                },
                                onDelete: {
                                    modelToDelete = modelName
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Models")
            .toolbar {
                if !viewModel.availableModels.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.showingCreateModel = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                    }
                }
                
            }
            .sheet(isPresented: $viewModel.showingCreateModel) {
                CreateModelSheet(
                    newModelName: $viewModel.newModelName,
                    isPresented: $viewModel.showingCreateModel,
                    onCreate: { name in
                        viewModel.createModel(name: name)
                    }
                )
            }
            .alert("Delete Model", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteModel(name: modelToDelete)
                }
            } message: {
                Text("Are you sure you want to delete '\(modelToDelete)'? This action cannot be undone.")
            }
            .loadingState(viewModel.loadingState, 
                         onRetry: { 
                             viewModel.refreshData() 
                         },
                         onDismiss: { 
                             viewModel.clearLoadingState() 
                         })
        }
    }
}

struct ModelRow: View {
    let modelName: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(modelName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    if isSelected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Selected for Training")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if !isSelected {
                    Button("Select") {
                        onSelect()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            if !isSelected {
                onSelect()
            }
        }
    }
}

struct CreateModelSheet: View {
    @Binding var newModelName: String
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model Name")
                        .font(.headline)
                    
                    TextField("Enter model name", text: $newModelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("Choose a descriptive name for your model (e.g., 'Glasses Classifier', 'Product Detector')")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                        newModelName = ""
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        if !newModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onCreate(newModelName.trimmingCharacters(in: .whitespacesAndNewlines))
                            isPresented = false
                            newModelName = ""
                        }
                    }
                    .disabled(newModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
