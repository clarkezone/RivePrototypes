//
//  ContentView.swift
//  RiveMenuPrototypes
//
//  Created by James Clarke on 3/24/26.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    private var riveViewModel = RiveViewModel(fileName: "digging_dinosaurs", stateMachineName: "State Machine 1")

    var body: some View {
        riveViewModel.view()
            .frame(maxWidth: 600, maxHeight: 600)
    }
}

#Preview {
    ContentView()
}
