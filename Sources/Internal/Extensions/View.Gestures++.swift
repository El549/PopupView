//
//  View.Gestures++.swift of PopupView
//
//  Created by Tomasz Kurylik
//    - Twitter: https://twitter.com/tkurylik
//    - Mail: tomasz.kurylik@mijick.com
//
//  Copyright ©2023 Mijick. Licensed under MIT License.


import SwiftUI

// MARK: - iOS + macOS Implementation
#if os(iOS) || os(macOS) || os(visionOS) || os(watchOS)
extension View {
    func onTapGesture(perform action: @escaping () -> ()) -> some View { onTapGesture(count: 1, perform: action) }
    func onDragGesture(_ state: GestureState<Bool>,enable: Binding<Bool>, onChanged actionOnChanged: @escaping (CGFloat) -> (), onEnded actionOnEnded: @escaping (CGFloat) -> ()) -> some View {
        func createGes() -> any View {
            let object: any View = if #available(iOS 18, *) {
                simultaneousGesture(
                    createDragGesture(
                        state,
                        actionOnChanged,
                        actionOnEnded
                    )
                )
            } else {
                gesture(
                    createDragGesture(
                        state,
                        actionOnChanged,
                        actionOnEnded
                    ),
                    including: .all
                )
            }
            return object
        }
        let v = createGes().onStateChange(state, actionOnEnded)
        return AnyView(v)
//        simultaneousGesture(
//            createDragGesture(
//                state,
//                actionOnChanged,
//                actionOnEnded
//            )
//        )
//        .onStateChange(state, actionOnEnded)
    }
}
private extension View {
    func createDragGesture(_ state: GestureState<Bool>, _ actionOnChanged: @escaping (CGFloat) -> (), _ actionOnEnded: @escaping (CGFloat) -> ()) -> some Gesture {
        DragGesture(minimumDistance: 15)
            .updating(state) { _, state, _ in state = true }
            .onChanged { actionOnChanged($0.translation.height) }
            .onEnded {
                if PopupManager.shared.enable == true &&
                    $0.velocity.height > 500 {
                    PopupManager.dismiss()
                }
                actionOnEnded($0.translation.height)
            }
    }
    func onStateChange(_ state: GestureState<Bool>, _ actionOnEnded: @escaping (CGFloat) -> ()) -> some View {
    #if os(visionOS)
        onChange(of: state.wrappedValue) { state.wrappedValue ? () : actionOnEnded(.zero) }
    #else
        onChange(of: state.wrappedValue) { $0 ? () : actionOnEnded(.zero) }
    #endif
    }
}


// MARK: - tvOS Implementation
#elseif os(tvOS)
extension View {
    func onTapGesture(perform action: () -> ()) -> some View { self }
    func onDragGesture(onChanged actionOnChanged: (CGFloat) -> (), onEnded actionOnEnded: (CGFloat) -> ()) -> some View { self }
}
#endif
