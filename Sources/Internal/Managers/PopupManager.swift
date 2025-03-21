//
//  PopupManager.swift of PopupView
//
//  Created by Tomasz Kurylik
//    - Twitter: https://twitter.com/tkurylik
//    - Mail: tomasz.kurylik@mijick.com
//
//  Copyright ©2023 Mijick. Licensed under MIT License.


import SwiftUI

public class PopupManager: ObservableObject {
    @Published private(set) var views: [any Popup] = [] { willSet { onViewsChanged(newValue) }}
    private(set) var presenting: Bool = true
    private(set) var popupsWithoutOverlay: [ID] = []
    private(set) var popupsToBeDismissed: [ID: DispatchSourceTimer] = [:]
    private(set) var popupActionsOnDismiss: [ID: () -> ()] = [:]
    var popupScrollViewOffset: [ID: CGPoint] = [:]

    public static let shared: PopupManager = .init()
    
    @Published public var enable = true
    @Published public var continueMove = true
    public var scrollViewOffset: CGPoint = .zero
    
    private init() {}
}
private extension PopupManager {
    func onViewsChanged(_ newViews: [any Popup]) { newViews
        .difference(from: views, by: { $0.id == $1.id })
        .forEach { switch $0 {
            case .remove(_, let element, _): popupActionsOnDismiss[element.id]?(); popupActionsOnDismiss.removeValue(forKey: element.id)
            default: return
        }}
    }
}

// MARK: - Operations
enum StackOperation {
    case insertAndReplace(any Popup), insertAndStack(any Popup)
    case removeLast, remove(ID), removeAllUpTo(ID), removeAll
}
extension PopupManager {
    static func performOperation(_ operation: StackOperation) { DispatchQueue.main.async {
        removePopupFromStackToBeDismissed(operation)
        updateOperationType(operation)
        switch operation {
        case .insertAndReplace(let popup):
            if shared.views.canBeInserted(popup) {
                shared.popupScrollViewOffset[popup.id] = .zero
                shared.scrollViewOffset = .zero
            }
        case .insertAndStack(let popup):
            if shared.views.canBeInserted(popup) {
                shared.popupScrollViewOffset[popup.id] = .zero
                shared.scrollViewOffset = .zero
            }
        case .removeLast:
            shared.popupScrollViewOffset.removeValue(forKey: shared.views.last?.id ?? .init())
        case .remove(let id):
            if let view = shared.views.first(where: { $0.id ~= id }) {
                shared.popupScrollViewOffset.removeValue(forKey: view.id)
            }
        case .removeAllUpTo(let id):
            //            if let index = lastIndex(where: predicate) { removeLast(count - index - 1) }
            if let index = shared.views.lastIndex(where: { popup in
                popup.id ~= id
            }) {
                let removeIndex = shared.views.count - index - 1
                shared.popupScrollViewOffset.removeValue(forKey: shared.views[removeIndex].id)
            }
        case .removeAll:
            shared.popupScrollViewOffset.removeAll()
        }
        shared.views.perform(operation)
        switch operation {
        case .removeLast:
            shared.scrollViewOffset = shared.popupScrollViewOffset[shared.views.last?.id ?? .init()] ?? .zero
        case .remove(let id):
            shared.scrollViewOffset = shared.popupScrollViewOffset[shared.views.last?.id ?? .init()] ?? .zero
        case .removeAllUpTo(let id): break
            shared.scrollViewOffset = shared.popupScrollViewOffset[shared.views.last?.id ?? .init()] ?? .zero
        case .removeAll:
            shared.scrollViewOffset = .zero
        default: break
        }
    }}
    static func dismissPopupAfter(_ popup: any Popup, _ seconds: Double) { shared.popupsToBeDismissed[popup.id] = DispatchSource.createAction(deadline: seconds) { performOperation(.remove(popup.id)) } }
    static func hideOverlay(_ popup: any Popup) { shared.popupsWithoutOverlay.append(popup.id) }
    static func onPopupDismiss(_ popup: any Popup, _ action: @escaping () -> ()) { shared.popupActionsOnDismiss[popup.id] = action }
}
private extension PopupManager {
    static func removePopupFromStackToBeDismissed(_ operation: StackOperation) {
        switch operation {
        case .removeLast:
            shared.popupsToBeDismissed.removeValue(forKey: shared.views.last?.id ?? .init())
            shared.popupScrollViewOffset.removeValue(forKey: shared.views.last?.id ?? .init())
        case .remove(let id):
            shared.popupsToBeDismissed.removeValue(forKey: id)
            shared.popupScrollViewOffset.removeValue(forKey: id)
        case .removeAllUpTo, .removeAll:
            shared.popupsToBeDismissed.removeAll()
            shared.popupScrollViewOffset.removeAll()
        default: break
        }
    }
    static func updateOperationType(_ operation: StackOperation) {
        switch operation {
        case .insertAndReplace, .insertAndStack:
            shared.enable = true
            shared.presenting = true
        case .removeLast, .remove, .removeAllUpTo, .removeAll:
            shared.enable = false
            shared.presenting = false
        }
    }
}

fileprivate extension [any Popup] {
    mutating func perform(_ operation: StackOperation) {
        hideKeyboard()
        performOperation(operation)
    }
}
private extension [any Popup] {
    func hideKeyboard() { KeyboardManager.hideKeyboard() }
    mutating func performOperation(_ operation: StackOperation) {
        switch operation {
            case .insertAndReplace(let popup): replaceLast(popup, if: canBeInserted(popup))
            case .insertAndStack(let popup): append(popup, if: canBeInserted(popup))
            case .removeLast: removeLast()
            case .remove(let id): removeAll(where: { $0.id ~= id })
            case .removeAllUpTo(let id): removeAllUpToElement(where: { $0.id ~= id })
            case .removeAll: removeAll()
        }
    }
}
private extension [any Popup] {
    func canBeInserted(_ popup: some Popup) -> Bool { !contains(where: { $0.id ~= popup.id }) }
}
