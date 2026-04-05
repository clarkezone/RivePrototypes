import SwiftUI
import RiveRuntime

struct ViewModelPropertyRow: View {
    @Bindable var property: ViewModelPropertyNode
    var onPropertyChanged: (() -> Void)?

    var body: some View {
        switch property.dataType {
        case .string:
            HStack {
                Text(property.name).font(.caption).monospaced()
                Spacer()
                TextField("", text: stringBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .frame(maxWidth: 140)
            }

        case .number, .integer:
            HStack {
                Text(property.name).font(.caption).monospaced()
                Spacer()
                TextField("", value: numberBinding, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .frame(width: 80)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }

        case .boolean:
            Toggle(isOn: boolBinding) {
                Text(property.name).font(.caption).monospaced()
            }

        case .color:
            ColorPicker(selection: colorBinding) {
                Text(property.name).font(.caption).monospaced()
            }

        case .enum:
            HStack {
                Text(property.name).font(.caption).monospaced()
                Spacer()
                Picker("", selection: enumBinding) {
                    ForEach(property.enumOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
            }

        case .trigger:
            Button {
                property.triggerProperty?.trigger()
                onPropertyChanged?()
            } label: {
                Label(property.name, systemImage: "bolt.fill")
                    .font(.caption).monospaced()
            }

        case .viewModel:
            if let child = property.childNode {
                DisclosureGroup {
                    ForEach(child.properties) { childProp in
                        ViewModelPropertyRow(property: childProp, onPropertyChanged: onPropertyChanged)
                    }
                } label: {
                    Label(property.name, systemImage: "rectangle.3.group")
                        .font(.caption).monospaced()
                }
            } else {
                HStack {
                    Text(property.name).font(.caption).monospaced()
                    Spacer()
                    Text("nil").font(.caption2).foregroundStyle(.secondary)
                }
            }

        case .list:
            DisclosureGroup {
                ForEach(Array(property.listItems.enumerated()), id: \.element.id) { index, item in
                    DisclosureGroup {
                        ForEach(item.properties) { childProp in
                            ViewModelPropertyRow(property: childProp)
                        }
                    } label: {
                        HStack {
                            Text("[\(index)]").font(.caption).monospaced()
                            Spacer()
                            Button(role: .destructive) {
                                property.removeListItem(at: index)
                                onPropertyChanged?()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption2)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                if property.allViewModels.count == 1 {
                    Button {
                        property.addListItem(using: property.allViewModels[0])
                        onPropertyChanged?()
                    } label: {
                        Label("Add Item", systemImage: "plus.circle")
                            .font(.caption)
                    }
                } else if property.allViewModels.count > 1 {
                    Menu {
                        ForEach(Array(property.allViewModels.enumerated()), id: \.offset) { _, vm in
                            Button(vm.name) {
                                property.addListItem(using: vm)
                                onPropertyChanged?()
                            }
                        }
                    } label: {
                        Label("Add Item", systemImage: "plus.circle")
                            .font(.caption)
                    }
                }
            } label: {
                Label("\(property.name) (\(property.listCount))", systemImage: "list.bullet")
                    .font(.caption).monospaced()
            }

        default:
            HStack {
                Text(property.name).font(.caption).monospaced()
                Spacer()
                Text(String(describing: property.dataType))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Bindings that write back to Rive

    private var stringBinding: Binding<String> {
        Binding(
            get: { property.stringValue },
            set: { newValue in
                property.stringValue = newValue
                property.stringProperty?.value = newValue
                onPropertyChanged?()
            }
        )
    }

    private var numberBinding: Binding<Float> {
        Binding(
            get: { property.numberValue },
            set: { newValue in
                property.numberValue = newValue
                property.numberProperty?.value = newValue
                onPropertyChanged?()
            }
        )
    }

    private var boolBinding: Binding<Bool> {
        Binding(
            get: { property.boolValue },
            set: { newValue in
                property.boolValue = newValue
                property.booleanProperty?.value = newValue
                onPropertyChanged?()
            }
        )
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { property.colorValue },
            set: { newColor in
                property.colorValue = newColor
                #if os(iOS) || os(visionOS) || os(tvOS)
                guard let uiColor = UIColor(newColor).cgColor.components, uiColor.count >= 3 else { return }
                let r = CGFloat(uiColor[0]) * 255
                let g = CGFloat(uiColor[1]) * 255
                let b = CGFloat(uiColor[2]) * 255
                let a = uiColor.count >= 4 ? CGFloat(uiColor[3]) * 255 : 255
                property.colorProperty?.set(red: r, green: g, blue: b, alpha: a)
                onPropertyChanged?()
                #else
                guard let nsColor = NSColor(newColor).usingColorSpace(.sRGB) else { return }
                property.colorProperty?.set(
                    red: nsColor.redComponent * 255,
                    green: nsColor.greenComponent * 255,
                    blue: nsColor.blueComponent * 255,
                    alpha: nsColor.alphaComponent * 255
                )
                onPropertyChanged?()
                #endif
            }
        )
    }

    private var enumBinding: Binding<String> {
        Binding(
            get: { property.enumValue },
            set: { newValue in
                property.enumValue = newValue
                property.enumProperty?.value = newValue
                onPropertyChanged?()
            }
        )
    }
}
