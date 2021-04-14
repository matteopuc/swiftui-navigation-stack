//
//  Push.swift
//  
//
//  Created by Matteo Puccinelli on 14/04/21.
//

import SwiftUI

/// A view used to navigate to another view through its enclosing NavigationStack.
public struct PushView<Label, Destination, Tag>: View where Label: View, Destination: View, Tag: Hashable {
    @EnvironmentObject private var navigationStack: NavigationStack
    private let label: Label?
    private let destinationId: String?
    private let destination: Destination
    private let tag: Tag?
    @Binding private var isActive: Bool
    @Binding private var selection: Tag?

    /// Creates a PushView that triggers the navigation on tap or when a tag matches a specific value.
    /// - Parameters:
    ///   - destination: The view to navigate to.
    ///   - destinationId: The ID of the destination view (used to easily come back to it if needed).
    ///   - tag: A value representing this push operation.
    ///   - selection: A binding that triggers the navigation if and when its value matches the tag value.
    ///   - label: The actual view to tap to trigger the navigation.
    public init(destination: Destination,
                destinationId: String? = nil,
                tag: Tag,
                selection: Binding<Tag?>,
                @ViewBuilder label: () -> Label) {

        self.init(destination: destination,
                  destinationId: destinationId,
                  isActive: Binding.constant(false),
                  tag: tag,
                  selection: selection,
                  label: label)
    }

    private init(destination: Destination,
                 destinationId: String?,
                 isActive: Binding<Bool>,
                 tag: Tag?,
                 selection: Binding<Tag?>,
                 @ViewBuilder label: () -> Label) {

        self.label = label()
        self.destinationId = destinationId
        self._isActive = isActive
        self.tag = tag
        self.destination = destination
        self._selection = selection
    }

    public var body: some View {
        if let selection = selection, let tag = tag, selection == tag {
            DispatchQueue.main.async {
                self.selection = nil
                push()
            }
        }
        if isActive {
            DispatchQueue.main.async {
                isActive = false
                push()
            }
        }
        return label.onTapGesture {
            push()
        }
    }

    private func push() {
        navigationStack.push(destination, withId: destinationId)
    }
}

public extension PushView where Tag == Never {

    /// Creates a PushView that triggers the navigation on tap.
    /// - Parameters:
    ///   - destination: The view to navigate to.
    ///   - destinationId: The ID of the destination view (used to easily come back to it if needed).
    ///   - label: The actual view to tap to trigger the navigation.
    init(destination: Destination,
         destinationId: String? = nil,
         @ViewBuilder label: () -> Label) {

        self.init(destination: destination,
                  destinationId: destinationId,
                  isActive: Binding.constant(false),
                  tag: nil,
                  selection: Binding.constant(nil),
                  label: label)
    }

    /// Creates a PushView that triggers the navigation on tap or when a boolean value becomes true.
    /// - Parameters:
    ///   - destination: The view to navigate to.
    ///   - destinationId: The ID of the destination view (used to easily come back to it if needed).
    ///   - isActive: A boolean binding that triggers the navigation if and when becomes true.
    ///   - label: The actual view to tap to trigger the navigation.
    init(destination: Destination,
         destinationId: String? = nil,
         isActive: Binding<Bool>,
         @ViewBuilder label: () -> Label) {

        self.init(destination: destination,
                  destinationId: destinationId,
                  isActive: isActive,
                  tag: nil,
                  selection: Binding.constant(nil),
                  label: label)
    }
}
