//
//  BaseView.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/30/25.
//

import SwiftUI
import VinceML

struct BaseView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var trainingDataService: TrainingDataService
    @EnvironmentObject private var mlModelService: MLModelService
    @EnvironmentObject private var cameraService: CameraService
    @EnvironmentObject private var modelManager: ModelManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TrainingView(
                viewModel: TrainingViewModel(
                    trainingDataService: trainingDataService,
                    mlModelService: mlModelService,
                    modelManager: modelManager
                )
            )
            .tabItem {
                Image(systemName: "camera.fill")
                Text("Train")
            }
            .tag(0)
            
            ClassificationView(
                viewModel: ClassificationViewModel(
                    mlModelService: mlModelService,
                    modelManager: modelManager,
                    cameraService: cameraService
                )
            )
            .tabItem {
                Image(systemName: "viewfinder")
                Text("Identify")
            }
            .tag(1)
            
            ModelManagementView(
                viewModel: ModelManagementViewModel(
                    modelManager: modelManager
                )
            )
            .tabItem {
                Image(systemName: "brain.head.profile")
                Text("Models")
            }
            .tag(2)
        }
    }
}

#Preview {
    BaseView()
}
