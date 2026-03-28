//
//  ContentView.swift
//  RiveMenuPrototypes
//
//  Created by James Clarke on 3/24/26.
//

import SwiftUI
import RiveRuntime

enum RiveAsset: String, CaseIterable, Identifiable {
    case diggingDinosaurs = "digging_dinosaurs"
    case sausagefest = "sausagefest"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .diggingDinosaurs: "Digging Dinosaurs"
        case .sausagefest: "Sausagefest"
        }
    }
}

struct ContentView: View {
    @State private var selectedAsset: RiveAsset = .diggingDinosaurs

    var body: some View {
        VStack {
            Picker("Animation", selection: $selectedAsset) {
                ForEach(RiveAsset.allCases) { asset in
                    Text(asset.displayName).tag(asset)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            RiveAssetView(asset: selectedAsset)
                .id(selectedAsset)
                .padding(20)
        }
    }
}

struct RiveAssetView: View {
    let asset: RiveAsset
    private let riveViewModel: RiveViewModel

    init(asset: RiveAsset) {
        self.asset = asset
        self.riveViewModel = RiveViewModel(fileName: asset.rawValue, stateMachineName: "State Machine 1")
    }

    var body: some View {
        riveViewModel.view()
    }
}

#Preview {
    ContentView()
}
