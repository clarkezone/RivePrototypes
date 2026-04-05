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
        .bundled(name: "layouttest", displayName: "Layout Test"),
        .bundled(name: "databindtest", displayName: "Data Bind Test"),
    ]
}

final class RiveViewHolder {
    var riveView: RiveView?

    func advance() {
        riveView?.advance(delta: 0)
    }
}

struct ContentView: View {
    @State private var selectedSource: RiveSource = RiveSource.builtInAssets[0]
    @State private var showingFilePicker = false
    @State private var showingInspector = false
    @State private var showingViewModelEditor = false
    @AppStorage("lockAspectRatio") private var lockAspectRatio = false
    @State private var reloadKey = 0
    @State private var errorMessage: String?
    @State private var debugInfo: RiveDebugInfo?
    @State private var dataBindingInstance: RiveDataBindingViewModel.Instance?
    @State private var riveFile: RiveFile?
    @State private var riveViewHolder = RiveViewHolder()

    var body: some View {
        ZStack(alignment: .trailing) {
            // Full-bleed Rive canvas
            VStack(spacing: 0) {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                RiveSourceView(source: selectedSource, debugInfo: $debugInfo, lockAspectRatio: $lockAspectRatio, dataBindingInstance: $dataBindingInstance, riveFile: $riveFile, riveViewHolder: riveViewHolder)
                    .id("\(selectedSource.id)-\(reloadKey)")
                    .ignoresSafeArea()
                    .accessibilityIdentifier("riveCanvas")
            }

            // Inspector overlay
            if showingInspector {
                RiveInspectorView(
                    debugInfo: debugInfo,
                    selectedSource: $selectedSource,
                    showingFilePicker: $showingFilePicker,
                    isPresented: $showingInspector
                )
                .transition(.move(edge: .trailing))
                .padding(.vertical, 8)
                .padding(.trailing, 8)
                .zIndex(1)
            }

            // View Model Editor overlay
            if showingViewModelEditor {
                ViewModelEditorView(
                    dataBindingInstance: dataBindingInstance,
                    riveFile: riveFile,
                    onPropertyChanged: { riveViewHolder.advance() },
                    isPresented: $showingViewModelEditor
                )
                .transition(.move(edge: .trailing))
                .padding(.vertical, 8)
                .padding(.trailing, showingInspector ? 316 : 8)
                .zIndex(2)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    lockAspectRatio.toggle()
                    reloadKey += 1
                } label: {
                    Label(
                        lockAspectRatio ? "Unlock Aspect Ratio" : "Lock Aspect Ratio",
                        systemImage: lockAspectRatio ? "aspectratio.fill" : "aspectratio"
                    )
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showingViewModelEditor.toggle()
                    }
                } label: {
                    Label("View Model", systemImage: "slider.horizontal.3")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showingInspector.toggle()
                    }
                } label: {
                    Label("Inspector", systemImage: "info.circle")
                }
            }
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
    var fitMode: String = "contain"
    var viewSize: CGSize = .zero
}

struct RiveSourceView: View {
    let source: RiveSource
    @Binding var debugInfo: RiveDebugInfo?
    @Binding var lockAspectRatio: Bool
    @Binding var dataBindingInstance: RiveDataBindingViewModel.Instance?
    @Binding var riveFile: RiveFile?
    let riveViewHolder: RiveViewHolder

    private var currentFit: RiveFit {
        lockAspectRatio ? .contain : .layout
    }

    @State private var riveViewModel: RiveViewModel?
    @State private var loadError: String?
    @State private var loadMethod: String = ""

    private func enableDefaultAutoBinding(for model: RiveModel) {
        model.enableAutoBind { instance in
            dataBindingInstance = instance
        }
    }

    private func loadSource() {
        loadError = nil

        switch source {
        case .bundled(let name, _):
            do {
                let file = try RiveFile(name: name)
                riveFile = file
                let model = RiveModel(riveFile: file)
                enableDefaultAutoBinding(for: model)
                riveViewModel = RiveViewModel(model, stateMachineName: nil, fit: currentFit)
                loadMethod = "RiveFile(name:) + enableAutoBind + RiveViewModel"
            } catch {
                loadError = error.localizedDescription
                loadMethod = "failed"
            }

        case .file(let url):
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    loadMethod = "failed"
                    loadError = "Unable to access file"
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                let file = try RiveFile(data: data, loadCdn: false)
                riveFile = file
                let model = RiveModel(riveFile: file)
                enableDefaultAutoBinding(for: model)
                riveViewModel = RiveViewModel(model, stateMachineName: nil, fit: currentFit)
                loadMethod = "RiveFile(data:) + enableAutoBind + RiveViewModel"
            } catch {
                loadError = error.localizedDescription
                loadMethod = "failed"
            }
        }
    }

    private func buildDebugInfo(viewSize: CGSize = .zero) -> RiveDebugInfo {
        var info = RiveDebugInfo()
        info.loadMethod = loadMethod
        info.fitMode = currentFit == .layout ? "layout" : "contain"
        info.viewSize = viewSize

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
        GeometryReader { geo in
            Group {
                if let riveViewModel {
                    riveViewModel.view()
                } else if let loadError {
                    ContentUnavailableView("Failed to Load", systemImage: "exclamationmark.triangle", description: Text(loadError))
                } else {
                    ProgressView()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                loadSource()
                riveViewHolder.riveView = riveViewModel?.riveView
            }
            .onChange(of: geo.size) {
                debugInfo = buildDebugInfo(viewSize: geo.size)
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    if let riveViewModel {
                        riveViewHolder.riveView = riveViewModel.riveView
                        debugInfo = buildDebugInfo(viewSize: geo.size)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
