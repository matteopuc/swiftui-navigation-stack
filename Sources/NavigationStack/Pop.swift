//
//  Pop.swift
//  
//
//  Created by Matteo Puccinelli on 14/04/21.
//

import SwiftUI

/// Defines the type of a pop operation.
public enum PopDestination {
    /// Pop back to the previous view.
    case previous

    /// Pop back to the root view (i.e. the first view added to the NavigationStackView during the initialization process).
    case root

    /// Pop back to a view identified by a specific ID.
    case view(withId: String)
}

/// A view used to navigate back to a previous view through its enclosing NavigationStack.
public struct PopView<Label, Tag>: View where Label: View, Tag: Hashable {
    @EnvironmentObject private var navigationStack: NavigationStack
    private let label: Label
    private let destination: PopDestination
    private let tag: Tag?
    @Binding private var isActive: Bool
    @Binding private var selection: Tag?

    /// Creates a PopView  that triggers the navigation on tap or when a tag matches a specific value.
    /// - Parameters:
    ///   - destination: The destination type of the pop operation.
    ///   - tag: A value representing this pop operation.
    ///   - selection: A binding that triggers the navigation if and when its value matches the tag value.
    ///   - label: The actual view to tap to trigger the navigation.
    public init(destination: PopDestination = .previous,
                tag: Tag, selection: Binding<Tag?>,
                @ViewBuilder label: () -> Label) {

        self.init(destination: destination,
                  isActive: Binding.constant(false),
                  tag: tag,
                  selection: selection,
                  label: label)
    }

    private init(destination: PopDestination,
                 isActive: Binding<Bool>, tag: Tag?,
                 selection: Binding<Tag?>,
                 @ViewBuilder label: () -> Label) {

        self.label = label()
        self.destination = destination
        self._isActive = isActive
        self._selection = selection
        self.tag = tag
    }

    public var body: some View {
        if let selection = selection, let tag = tag, selection == tag {
            DispatchQueue.main.async {
                self.selection = nil
                pop()
            }
        }
        if isActive {
            DispatchQueue.main.async {
                isActive = false
                pop()
            }
        }
        return label.onTapGesture {
            pop()
        }
    }

    private func pop() {
        navigationStack.pop(to: destination)
    }
}

public extension PopView where Tag == Never {

    /// Creates a PopView  that triggers the navigation on tap.
    /// - Parameters:
    ///   - destination: The destination type of the pop operation.
    ///   - label: The actual view to tap to trigger the navigation.
    init(destination: PopDestination = .previous,
         @ViewBuilder label: () -> Label) {

        self.init(destination: destination,
                  isActive: Binding.constant(false),
                  tag: nil,
                  selection: Binding.constant(nil),
                  label: label)
    }

    /// Creates a PopView  that triggers the navigation on tap or when a boolean value becomes true.
    /// - Parameters:
    ///   - destination: The destination type of the pop operation.
    ///   - isActive: A boolean binding that triggers the navigation if and when becomes true.
    ///   - label: The actual view to tap to trigger the navigation.
    init(destination: PopDestination = .previous,
         isActive: Binding<Bool>,
         @ViewBuilder label: () -> Label) {

        self.init(destination: destination,
                  isActive: isActive,
                  tag: nil,
                  selection: Binding.constant(nil),
                  label: label)
    }
}
