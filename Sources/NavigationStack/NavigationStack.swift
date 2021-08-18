//
//  NavigationStack.swift
//
//  Created by Matteo Puccinelli on 28/11/2019.

import SwiftUI

enum NavigationType {
    case push
    case pop
}


/** The manager behind the `NavigationStackView`. It also enables programmatic navigation.

 A `NavigationStack` is automatically injected as an `@EnvironmentObject` into a `NavigationStackView` hierarchy.

 Also, it can be created outside of a `NavigationStackView` hierarchy and injected manually into it during the `NavigationStackView` initialization process.
*/
public class NavigationStack: ObservableObject {

    /// The default easing function for push and pop transitions.
    /// - Tag: defaultEasing
    public static let defaultEasing = Animation.easeOut(duration: 0.2)

    @Published var currentView: ViewElement?
    private(set) var navigationType = NavigationType.push
    private let easing: Animation

    /// Creates a NavigationStack.
    /// - Parameter easing: The easing function to apply to push and pop transitions. By default, the [default easing function](x-source-tag://defaultEasing) will be used.
    public init(easing: Animation = defaultEasing) {
        self.easing = easing
    }

    private var viewStack = ViewStack() {
        didSet {
            currentView = viewStack.peek()
        }
    }

    /// The current depth of the navigation stack.
    /// Root has depth = 0
    public var depth: Int {
        viewStack.depth
    }

    /// Navigates to a view.
    /// - Parameters:
    ///   - element: The destination view.
    ///   - identifier: The ID of the destination view (used to easily come back to it if needed).
    public func push<Element: View>(_ element: Element, withId identifier: String? = nil) {
        withAnimation(easing) {
            navigationType = .push
            viewStack.push(ViewElement(id: identifier == nil ? UUID().uuidString : identifier!,
                                       wrappedElement: AnyView(element)))
        }
    }

    /// Navigates back to a previous view.
    /// - Parameter to: The destination type of the transition operation.
    public func pop(to: PopDestination = .previous) {
        withAnimation(easing) {
            navigationType = .pop
            switch to {
            case .root:
                viewStack.popToRoot()
            case .view(let viewId):
                viewStack.popToView(withId: viewId)
            default:
                viewStack.popToPrevious()
            }
        }
    }

    //the actual stack
    private struct ViewStack {
        private var views = [ViewElement]()

        func peek() -> ViewElement? {
            views.last
        }

        var depth: Int {
            views.count
        }

        mutating func push(_ element: ViewElement) {
            guard indexForView(withId: element.id) == nil else {
                print("Duplicated view identifier: \"\(element.id)\". You are trying to push a view with an identifier that already exists on the navigation stack.")
                return
            }
            views.append(element)
        }

        mutating func popToPrevious() {
            _ = views.popLast()
        }

        mutating func popToView(withId identifier: String) {
            guard let viewIndex = indexForView(withId: identifier) else {
                print("Identifier \"\(identifier)\" not found. You are trying to pop to a view that doesn't exist.")
                return
            }
            views.removeLast(views.count - (viewIndex + 1))
        }

        mutating func popToRoot() {
            views.removeAll()
        }

        private func indexForView(withId identifier: String) -> Int? {
            views.firstIndex {
                $0.id == identifier
            }
        }
    }
}

//the actual element in the stack
struct ViewElement: Identifiable, Equatable {
    let id: String
    let wrappedElement: AnyView

    static func == (lhs: ViewElement, rhs: ViewElement) -> Bool {
        lhs.id == rhs.id
    }
}
