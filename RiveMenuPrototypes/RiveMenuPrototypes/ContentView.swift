//
//  ContentView.swift
//  RiveMenuPrototypes
//
//  Created by James Clarke on 3/24/26.
//

import SwiftUI
import RiveRuntime
import UniformTypeIdentifiers

extension UTType {
    static var riv: UTType {
        UTType(filenameExtension: "riv") ?? .data
    }
}

/// Represents the source of a Rive animation — either a bundled asset or a user-selected file.
enum RiveSource: Hashable, Identifiable {
    case bundled(name: String, displayName: String)
    case file(url: URL)

    var id: String {
        switch self {
        case .bundled(let name, _): "bundled-\(name)"
        case .file(let url): "file-\(url.absoluteString)"
        }
    }

    var displayName: String {
        switch self {
        case .bundled(_, let displayName): displayName
        case .file(let url): url.lastPathComponent
        }
    }

    static let builtInAssets: [RiveSource] = [
        .bundled(name: "digging_dinosaurs", displayName: "Digging Dinosaurs"),
        .bundled(name: "sausagefest", displayName: "Sausagefest"),
    ]
}

struct ContentView: View {
    @State private var selectedSource: RiveSource = RiveSource.builtInAssets[0]
    @State private var showingFilePicker = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            HStack {
                Picker("Animation", selection: $selectedSource) {
                    ForEach(RiveSource.builtInAssets) { source in
                        Text(source.displayName).tag(source)
                    }
                    if case .file = selectedSource {
                        Text(selectedSource.displayName).tag(selectedSource)
                    }
                }
                .pickerStyle(.menu)

                Button("Open File...") {
                    showingFilePicker = true
                }
            }
            .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            RiveSourceView(source: selectedSource)
                .id(selectedSource)
                .padding(20)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.riv],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    errorMessage = nil
                    selectedSource = .file(url: url)
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct RiveSourceView: View {
    let source: RiveSource
    private let riveViewModel: RiveViewModel?
    private let loadError: String?

    init(source: RiveSource) {
        self.source = source
        switch source {
        case .bundled(let name, _):
            self.riveViewModel = RiveViewModel(fileName: name, stateMachineName: "State Machine 1")
            self.loadError = nil
        case .file(let url):
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    self.riveViewModel = nil
                    self.loadError = "Unable to access file"
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                let riveFile = try RiveFile(data: data, loadCdn: false)
                let model = RiveModel(riveFile: riveFile)
                self.riveViewModel = RiveViewModel(model, stateMachineName: nil)
                self.loadError = nil
            } catch {
                self.riveViewModel = nil
                self.loadError = error.localizedDescription
            }
        }
    }

    var body: some View {
        if let riveViewModel {
            riveViewModel.view()
        } else if let loadError {
            ContentUnavailableView("Failed to Load", systemImage: "exclamationmark.triangle", description: Text(loadError))
        }
    }
}

#Preview {
    ContentView()
}
