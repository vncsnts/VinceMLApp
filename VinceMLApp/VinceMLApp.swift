//
//  VinceMLApp.swift
//  VinceML
//
//  Created by Vince Carlo Santos on 7/29/25.
//

import SwiftUI
import VinceML

@main
struct VinceMLApp: App {
    @StateObject private var trainingDataService = TrainingDataService()
    @StateObject private var mlModelService = MLModelService()
    @StateObject private var cameraService = CameraService()
    @StateObject private var modelManager = ModelManager()
    
    var body: some Scene {
        WindowGroup {
            BaseView()
                .environmentObject(trainingDataService)
                .environmentObject(mlModelService)
                .environmentObject(cameraService)
                .environmentObject(modelManager)
        }
    }
}
