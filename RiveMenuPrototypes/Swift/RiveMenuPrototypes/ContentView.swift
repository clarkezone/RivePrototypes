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
        .bundled(name: "digging_dinosaurs-2", displayName: "Digging Dinosaurs"),
        .bundled(name: "sausagefest", displayName: "Sausagefest"),
    ]
}

struct ContentView: View {
    @State private var selectedSource: RiveSource = RiveSource.builtInAssets[0]
    @State private var showingFilePicker = false
    @State private var showingInspector = false
    @State private var errorMessage: String?
    @State private var debugInfo: RiveDebugInfo?

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

                Spacer()

                Button {
                    showingInspector.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
            }
            .padding(.horizontal)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            RiveSourceView(source: selectedSource, debugInfo: $debugInfo)
                .id(selectedSource)
                .padding(20)
        }
        .inspector(isPresented: $showingInspector) {
            RiveInspectorView(debugInfo: debugInfo)
                .inspectorColumnWidth(min: 250, ideal: 300, max: 400)
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

struct RiveDebugInfo {
    var artboardNames: [String] = []
    var defaultArtboardName: String?
    var stateMachineNames: [String] = []
    var defaultStateMachineName: String?
    var animationNames: [String] = []
    var viewModelCount: Int = 0
    var activeStateMachine: String?
    var activeAnimation: String?
    var loadMethod: String = ""
    var error: String?

    // Runtime state
    var isPlaying: Bool = false
    var autoPlay: Bool = true
    var hasRiveView: Bool = false
    var hasRiveModel: Bool = false
    var hasArtboard: Bool = false
    var hasStateMachineInstance: Bool = false
    var hasAnimationInstance: Bool = false
    var stateMachineInputs: [(name: String, type: String)] = []
    var stateMachineLayerCount: Int = 0
    var stateChanges: [String] = []
    var artboardBounds: CGRect = .zero
}

struct RiveInspectorView: View {
    let debugInfo: RiveDebugInfo?

    var body: some View {
        List {
            if let info = debugInfo {
                if let error = info.error {
                    Section("Error") {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section("Load Method") {
                    Text(info.loadMethod).font(.caption).monospaced()
                }

                Section("Runtime State") {
                    debugRow("isPlaying", value: info.isPlaying, good: true)
                    if !info.isPlaying && info.hasStateMachineInstance {
                        Text("SM settled (waiting for input)")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                    debugRow("autoPlay", value: info.autoPlay, good: true)
                    debugRow("hasRiveView", value: info.hasRiveView, good: true)
                    debugRow("hasRiveModel", value: info.hasRiveModel, good: true)
                    debugRow("hasArtboard", value: info.hasArtboard, good: true)
                    debugRow("hasStateMachine", value: info.hasStateMachineInstance, good: true)
                    debugRow("hasAnimation", value: info.hasAnimationInstance, good: false)
                }

                Section("Artboards (\(info.artboardNames.count))") {
                    ForEach(info.artboardNames, id: \.self) { name in
                        HStack {
                            Text(name).font(.caption).monospaced()
                            if name == info.defaultArtboardName {
                                Spacer()
                                Text("default").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if info.hasArtboard {
                        Text("bounds: \(Int(info.artboardBounds.width))x\(Int(info.artboardBounds.height))")
                            .font(.caption).monospaced().foregroundStyle(.secondary)
                    }
                }

                Section("State Machines (\(info.stateMachineNames.count))") {
                    if info.stateMachineNames.isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    }
                    ForEach(info.stateMachineNames, id: \.self) { name in
                        HStack {
                            Text(name).font(.caption).monospaced()
                            Spacer()
                            if name == info.defaultStateMachineName {
                                Text("default").font(.caption2).foregroundStyle(.secondary)
                            }
                            if name == info.activeStateMachine {
                                Text("active").font(.caption2).foregroundStyle(.green)
                            }
                        }
                    }
                    if info.hasStateMachineInstance {
                        Text("layers: \(info.stateMachineLayerCount)")
                            .font(.caption).monospaced().foregroundStyle(.secondary)
                    }
                }

                if !info.stateMachineInputs.isEmpty {
                    Section("SM Inputs (\(info.stateMachineInputs.count))") {
                        ForEach(info.stateMachineInputs, id: \.name) { input in
                            HStack {
                                Text(input.name).font(.caption).monospaced()
                                Spacer()
                                Text(input.type).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !info.stateChanges.isEmpty {
                    Section("State Changes") {
                        ForEach(info.stateChanges, id: \.self) { change in
                            Text(change).font(.caption).monospaced()
                        }
                    }
                }

                Section("Animations (\(info.animationNames.count))") {
                    if info.animationNames.isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    }
                    ForEach(info.animationNames, id: \.self) { name in
                        HStack {
                            Text(name).font(.caption).monospaced()
                            if name == info.activeAnimation {
                                Spacer()
                                Text("active").font(.caption2).foregroundStyle(.green)
                            }
                        }
                    }
                }

                Section("Data Binding") {
                    Text("View Models: \(info.viewModelCount)")
                        .font(.caption).monospaced()
                }
            } else {
                Text("No file loaded").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Rive Inspector")
    }

    private func debugRow(_ label: String, value: Bool, good: Bool) -> some View {
        HStack {
            Text(label).font(.caption).monospaced()
            Spacer()
            Text(value ? "YES" : "NO")
                .font(.caption).monospaced()
                .foregroundStyle(value == good ? .green : .red)
        }
    }
}

struct RiveSourceView: View {
    let source: RiveSource
    @Binding var debugInfo: RiveDebugInfo?
    @State private var riveViewModel: RiveViewModel?
    @State private var loadError: String?
    @State private var loadMethod: String = ""
    @State private var didLoad = false

    private func loadSource() {
        guard !didLoad else { return }
        didLoad = true

        switch source {
        case .bundled(let name, _):
            loadMethod = "RiveViewModel(fileName: \"\(name)\")"
            riveViewModel = RiveViewModel(fileName: name)

        case .file(let url):
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    loadMethod = "failed"
                    loadError = "Unable to access file"
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                let riveFile = try RiveFile(data: data, loadCdn: false)
                let model = RiveModel(riveFile: riveFile)
                riveViewModel = RiveViewModel(model, stateMachineName: nil)
                loadMethod = "RiveFile(data:) + RiveModel + RiveViewModel"
            } catch {
                loadError = error.localizedDescription
                loadMethod = "failed"
            }
        }

        debugInfo = buildDebugInfo()
    }

    private func buildDebugInfo() -> RiveDebugInfo {
        var info = RiveDebugInfo()
        info.loadMethod = loadMethod

        if let error = loadError {
            info.error = error
            return info
        }

        guard let vm = riveViewModel else {
            info.error = "RiveViewModel is nil"
            return info
        }

        info.isPlaying = vm.isPlaying
        info.autoPlay = vm.autoPlay
        info.hasRiveView = vm.riveView != nil
        info.hasRiveModel = vm.riveModel != nil

        guard let model = vm.riveModel else {
            info.error = "RiveModel is nil after init"
            return info
        }

        let file = model.riveFile
        info.artboardNames = file.artboardNames() as? [String] ?? []

        if let defaultArtboard = try? file.artboard() {
            info.defaultArtboardName = defaultArtboard.name()
        }

        info.hasArtboard = model.artboard != nil

        if let artboard = model.artboard {
            info.stateMachineNames = artboard.stateMachineNames() as? [String] ?? []
            info.animationNames = artboard.animationNames() as? [String] ?? []
            info.artboardBounds = artboard.bounds()

            if let defaultSM = artboard.defaultStateMachine() {
                info.defaultStateMachineName = defaultSM.name()
            }
        }

        info.hasStateMachineInstance = model.stateMachine != nil
        info.hasAnimationInstance = model.animation != nil

        if let sm = model.stateMachine {
            info.activeStateMachine = sm.name()
            info.stateMachineLayerCount = Int(sm.layerCount())
            info.stateChanges = sm.stateChanges() as? [String] ?? []

            let inputCount = Int(sm.inputCount())
            for i in 0..<inputCount {
                if let input = try? sm.input(from: i) {
                    let typeName: String
                    if input is RiveSMIBool {
                        typeName = "Bool"
                    } else if input is RiveSMINumber {
                        typeName = "Number"
                    } else if input is RiveSMITrigger {
                        typeName = "Trigger"
                    } else {
                        typeName = "Unknown"
                    }
                    info.stateMachineInputs.append((name: input.name(), type: typeName))
                }
            }
        }

        if let anim = model.animation {
            info.activeAnimation = anim.name()
        }

        info.viewModelCount = Int(file.viewModelCount)
        return info
    }

    var body: some View {
        Group {
            if let riveViewModel {
                riveViewModel.view()
            } else if let loadError {
                ContentUnavailableView("Failed to Load", systemImage: "exclamationmark.triangle", description: Text(loadError))
            } else {
                ProgressView()
            }
        }
        .onAppear { loadSource() }
        .task {
            // Live-update debug info every second so we can see runtime state changes
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if riveViewModel != nil {
                    debugInfo = buildDebugInfo()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
