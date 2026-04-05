import SwiftUI
import RiveRuntime

struct ViewModelEditorView: View {
    let dataBindingInstance: RiveDataBindingViewModel.Instance?
    let riveFile: RiveFile?
    var onPropertyChanged: (() -> Void)?
    @Binding var isPresented: Bool
    @State private var rootNode: ViewModelNode?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("View Model")
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

            if let rootNode {
                List {
                    Section(rootNode.name) {
                        ForEach(rootNode.properties) { property in
                            ViewModelPropertyRow(property: property, onPropertyChanged: onPropertyChanged)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                ContentUnavailableView(
                    "No View Model",
                    systemImage: "rectangle.dashed",
                    description: Text("This animation has no data binding.")
                )
            }
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 12, x: -4, y: 0)
        .onAppear { buildRootNode() }
        .onChange(of: dataBindingInstance) { buildRootNode() }
    }

    private func buildRootNode() {
        guard let dataBindingInstance else {
            rootNode = nil
            return
        }
        var vmDef: RiveDataBindingViewModel?
        if let riveFile {
            // Try to get the first view model definition for list item creation
            if riveFile.viewModelCount > 0 {
                vmDef = riveFile.viewModel(at: 0)
            }
        }
        rootNode = ViewModelNode(instance: dataBindingInstance, viewModelDefinition: vmDef)
    }
}
