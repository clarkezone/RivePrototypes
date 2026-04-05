import Foundation
import RiveRuntime
import SwiftUI
import Observation

@Observable
final class ViewModelNode: Identifiable {
    let id = UUID()
    let name: String
    let instance: RiveDataBindingViewModel.Instance
    var properties: [ViewModelPropertyNode] = []

    init(instance: RiveDataBindingViewModel.Instance, allViewModels: [RiveDataBindingViewModel] = []) {
        self.name = instance.name
        self.instance = instance
        self.properties = Self.discoverProperties(from: instance, allViewModels: allViewModels)
    }

    private static func discoverProperties(
        from instance: RiveDataBindingViewModel.Instance,
        allViewModels: [RiveDataBindingViewModel]
    ) -> [ViewModelPropertyNode] {
        instance.properties.compactMap { propData in
            ViewModelPropertyNode(
                instance: instance,
                propertyData: propData,
                allViewModels: allViewModels
            )
        }
    }
}

@Observable
final class ViewModelPropertyNode: Identifiable {
    let id = UUID()
    let name: String
    let dataType: RiveDataBindingViewModel.Instance.Property.Data.DataType

    // Typed SDK property references (exactly one populated based on dataType)
    private(set) var stringProperty: RiveDataBindingViewModel.Instance.StringProperty?
    private(set) var numberProperty: RiveDataBindingViewModel.Instance.NumberProperty?
    private(set) var booleanProperty: RiveDataBindingViewModel.Instance.BooleanProperty?
    private(set) var colorProperty: RiveDataBindingViewModel.Instance.ColorProperty?
    private(set) var enumProperty: RiveDataBindingViewModel.Instance.EnumProperty?
    private(set) var triggerProperty: RiveDataBindingViewModel.Instance.TriggerProperty?
    private(set) var listProperty: RiveDataBindingViewModel.Instance.ListProperty?

    // Cached SwiftUI-friendly values
    var stringValue: String = ""
    var numberValue: Float = 0
    var boolValue: Bool = false
    var colorValue: Color = .clear
    var enumValue: String = ""
    var enumOptions: [String] = []

    // Nested structures
    var childNode: ViewModelNode?
    var listItems: [ViewModelNode] = []
    var listCount: Int = 0

    // For creating new list items — all available view model definitions
    private(set) var allViewModels: [RiveDataBindingViewModel] = []

    private var listenerID: UUID?

    init?(instance: RiveDataBindingViewModel.Instance,
          propertyData: RiveDataBindingViewModel.Instance.Property.Data,
          allViewModels: [RiveDataBindingViewModel]) {
        self.name = propertyData.name
        self.dataType = propertyData.type
        self.allViewModels = allViewModels

        switch dataType {
        case .string:
            guard let prop = instance.stringProperty(fromPath: name) else { return nil }
            stringProperty = prop
            stringValue = prop.value
            listenerID = prop.addListener { [weak self] newValue in
                DispatchQueue.main.async {
                    guard self?.stringValue != newValue else { return }
                    self?.stringValue = newValue
                }
            }

        case .number, .integer:
            guard let prop = instance.numberProperty(fromPath: name) else { return nil }
            numberProperty = prop
            numberValue = prop.value
            listenerID = prop.addListener { [weak self] newValue in
                DispatchQueue.main.async {
                    guard self?.numberValue != newValue else { return }
                    self?.numberValue = newValue
                }
            }

        case .boolean:
            guard let prop = instance.booleanProperty(fromPath: name) else { return nil }
            booleanProperty = prop
            boolValue = prop.value
            listenerID = prop.addListener { [weak self] newValue in
                DispatchQueue.main.async {
                    guard self?.boolValue != newValue else { return }
                    self?.boolValue = newValue
                }
            }

        case .color:
            guard let prop = instance.colorProperty(fromPath: name) else { return nil }
            colorProperty = prop
            colorValue = Color(prop.value)
            listenerID = prop.addListener { [weak self] newColor in
                DispatchQueue.main.async {
                    self?.colorValue = Color(newColor)
                }
            }

        case .enum:
            guard let prop = instance.enumProperty(fromPath: name) else { return nil }
            enumProperty = prop
            enumOptions = prop.values as? [String] ?? []
            enumValue = prop.value
            listenerID = prop.addListener { [weak self] newValue in
                DispatchQueue.main.async {
                    guard self?.enumValue != newValue else { return }
                    self?.enumValue = newValue
                }
            }

        case .trigger:
            guard let prop = instance.triggerProperty(fromPath: name) else { return nil }
            triggerProperty = prop

        case .viewModel:
            if let childInstance = instance.viewModelInstanceProperty(fromPath: name) {
                childNode = ViewModelNode(instance: childInstance, allViewModels: allViewModels)
            }

        case .list:
            guard let prop = instance.listProperty(fromPath: name) else { return nil }
            listProperty = prop
            rebuildListItems()
            listenerID = prop.addListener { [weak self] in
                DispatchQueue.main.async {
                    self?.rebuildListItems()
                }
            }

        default:
            // assetImage, artboard, input, symbolListIndex, none, any — read-only
            break
        }
    }

    deinit {
        if let listenerID {
            switch dataType {
            case .string: stringProperty?.removeListener(listenerID)
            case .number, .integer: numberProperty?.removeListener(listenerID)
            case .boolean: booleanProperty?.removeListener(listenerID)
            case .color: colorProperty?.removeListener(listenerID)
            case .enum: enumProperty?.removeListener(listenerID)
            case .trigger: triggerProperty?.removeListener(listenerID)
            case .list: listProperty?.removeListener(listenerID)
            default: break
            }
        }
    }

    func rebuildListItems() {
        guard let listProperty else { return }
        let count = Int(listProperty.count)
        listCount = count
        listItems = (0..<count).compactMap { index in
            guard let itemInstance = listProperty.instance(at: Int32(index)) else { return nil }
            return ViewModelNode(instance: itemInstance, allViewModels: allViewModels)
        }
    }

    func addListItem(using viewModel: RiveDataBindingViewModel) {
        guard let listProperty else { return }
        guard let newInstance = viewModel.createInstance() else { return }
        listProperty.append(newInstance)
        rebuildListItems()
    }

    func removeListItem(at index: Int) {
        guard let listProperty else { return }
        listProperty.remove(at: Int32(index))
        rebuildListItems()
    }
}
