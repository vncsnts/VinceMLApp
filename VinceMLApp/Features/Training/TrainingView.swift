//
//  TrainingView.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import Foundation
import SwiftUI

struct TrainingView: View {
    @State private var viewModel: TrainingViewModel
    
    init(viewModel: TrainingViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Selected Model Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Training Model")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: viewModel.trainModel) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                Text("Train")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.trainButtonEnabled ? Color.green : Color.gray)
                            .cornerRadius(8)
                        }
                        .disabled(!viewModel.trainButtonEnabled)
                    }
                    
                    if let selectedModel = viewModel.selectedModelName {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                            Text(selectedModel)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("No model selected")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            Text("Go to Models tab to create or select a model for training")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                // Statistics Card Component
                StatisticCardView(viewModel: viewModel.statisticsCardViewModel)
                
                // Label Selection Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select or Create Label")
                        .font(.headline)
                    
                    LabelChipCollection(
                        labels: Array(viewModel.availableLabels).sorted(),
                        selectedLabel: $viewModel.selectedLabel,
                        onAddNew: viewModel.showLabelInput
                    )
                }
                
                // Batch Capture Button Component
                ActionButtonView(
                    title: "Capture Training Images",
                    icon: "camera.on.rectangle",
                    isEnabled: Binding(
                        get: { viewModel.captureButtonEnabled },
                        set: { _ in }
                    ),
                    style: .primary,
                    action: viewModel.showBatchCapture
                )
                

                
                // Training Images Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(Dictionary(grouping: viewModel.trainingImages, by: \.label).sorted(by: { $0.key < $1.key }), id: \.key) { label, images in
                            Section {
                                ForEach(images) { image in
                                    ImageGridItem(
                                        imageProvider: .trainingImage(image, modelName: viewModel.selectedModelName),
                                        showDate: true,
                                        size: CGSize(width: 100, height: 100),
                                        onDelete: {
                                            viewModel.deleteTrainingImage(id: image.id)
                                        }
                                    )
                                }
                            } header: {
                                HStack {
                                    Text(label)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Training")
            .sheet(isPresented: $viewModel.showingBatchCapture) {
                CaptureImageFlowView(
                    viewModel: CaptureImageFlowViewModel(
                        trainingViewModel: viewModel,
                        selectedLabel: viewModel.selectedLabel
                    ),
                    onDismiss: viewModel.dismissBatchCapture
                )
            }
            .sheet(isPresented: $viewModel.showingLabelInput) {
                LabelInputSheet(
                    newLabel: $viewModel.newLabel,
                    isPresented: $viewModel.showingLabelInput,
                    onAdd: viewModel.addNewLabel,
                    onCancel: viewModel.cancelLabelInput
                )
            }
            .onAppear {
                viewModel.refreshData()
            }
            .loadingState(viewModel.loadingState, 
                         onRetry: { 
                             Task { viewModel.trainModel() }
                         },
                         onDismiss: { 
                             viewModel.clearLoadingState() 
                         })
        }
    }
}

struct LabelInputSheet: View {
    @Binding var newLabel: String
    @Binding var isPresented: Bool
    let onAdd: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter new label", text: $newLabel)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(newLabel)
                    }
                    .disabled(newLabel.isEmpty)
                }
            }
        }
    }
}
