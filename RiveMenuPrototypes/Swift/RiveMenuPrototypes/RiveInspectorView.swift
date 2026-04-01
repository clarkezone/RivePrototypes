import SwiftUI
import RiveRuntime
import UniformTypeIdentifiers

struct RiveInspectorView: View {
    let debugInfo: RiveDebugInfo?
    @Binding var selectedSource: RiveSource
    @Binding var showingFilePicker: Bool
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Inspector")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()

            List {
                // File picker section
                Section("Source") {
                    Picker("Animation", selection: $selectedSource) {
                        ForEach(RiveSource.builtInAssets) { source in
                            Text(source.displayName).tag(source)
                        }
                        if case .file = selectedSource {
                            Text(selectedSource.displayName).tag(selectedSource)
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Open File...", systemImage: "doc.badge.plus")
                    }
                }

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
                        HStack {
                            Text("fit").font(.caption).monospaced()
                            Spacer()
                            Text(info.fitMode)
                                .font(.caption).monospaced()
                                .foregroundStyle(info.fitMode == "layout" ? .green : .secondary)
                                .accessibilityIdentifier("fitModeValue")
                        }
                        HStack {
                            Text("viewSize").font(.caption).monospaced()
                            Spacer()
                            Text("\(Int(info.viewSize.width))x\(Int(info.viewSize.height))")
                                .font(.caption).monospaced()
                                .foregroundStyle(.secondary)
                        }
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
            .listStyle(.insetGrouped)
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 12, x: -4, y: 0)
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
