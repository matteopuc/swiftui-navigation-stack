//
//  NavigationStack.swift
//
//  Created by Matteo Puccinelli on 28/11/2019.

import SwiftUI

/// The transition type for the whole NavigationStackView.
public enum NavigationTransition {
    /// Transitions won't be animated.
    case none

    /// Use the [default transition](x-source-tag://defaultTransition).
    case `default`

    /// Use a custom transition (the transition will be applied both to push and pop operations).
    case custom(AnyTransition)

    /// A right-to-left slide transition on push, a left-to-right slide transition on pop.
    /// - Tag: defaultTransition
    public static var defaultTransitions: (push: AnyTransition, pop: AnyTransition) {
        let pushTrans = AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        let popTrans = AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        return (pushTrans, popTrans)
    }
}

private enum NavigationType {
    case push
    case pop
}

/// Defines the type of a pop operation.
public enum PopDestination {
    /// Pop back to the previous view.
    case previous

    /// Pop back to the root view (i.e. the first view added to the NavigationStackView during the initialization process).
    case root

    /// Pop back to a view identified by a specific ID.
    case view(withId: String)
}

// MARK: ViewModel

public class NavigationStack: ObservableObject {

    /// Default transition animation
    public static let defaultEasing = Animation.easeOut(duration: 0.2)

    fileprivate private(set) var navigationType = NavigationType.push

    /// Customizable easing to apply in pop and push transitions
    private let easing: Animation

    public init(easing: Animation = defaultEasing) {
        self.easing = easing
    }

    private var viewStack = ViewStack() {
        didSet {
            currentView = viewStack.peek()
        }
    }

    @Published fileprivate var currentView: ViewElement?

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
private struct ViewElement: Identifiable, Equatable {
    let id: String
    let wrappedElement: AnyView

    static func == (lhs: ViewElement, rhs: ViewElement) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Views

/// An alternative SwiftUI NavigationView implementing classic stack-based navigation giving also some more control on animations and programmatic navigation.
public struct NavigationStackView<Root>: View where Root: View {
    @ObservedObject private var navViewModel: NavigationStack
    private let rootViewID = "root"
    private let rootView: Root
    private let transitions: (push: AnyTransition, pop: AnyTransition)

    /// Creates a NavigationStackView.
    /// - Parameters:
    ///   - transitionType: The type of transition to apply between views in every push and pop operation.
    ///   - easing: The easing function to apply to every push and pop operation.
    ///   - rootView: The very first view in the NavigationStack.
    public init(transitionType: NavigationTransition = .default, easing: Animation = NavigationStack.defaultEasing, @ViewBuilder rootView: () -> Root) {
        self.init(transitionType: transitionType, navigationStack: NavigationStack(easing: easing), rootView: rootView)
    }

    /// Creates a NavigationStackView with the provided NavigationStack
    /// - Parameters:
    ///   - transitionType: The type of transition to apply between views in every push and pop operation.
    ///   - navigationStack: the shared NavigationStack
    ///   - rootView: The very first view in the NavigationStack.
    public init(transitionType: NavigationTransition = .default, navigationStack: NavigationStack, @ViewBuilder rootView: () -> Root) {
        self.rootView = rootView()
        self.navViewModel = navigationStack
        switch transitionType {
        case .none:
            self.transitions = (.identity, .identity)
        case .custom(let trans):
            self.transitions = (trans, trans)
        default:
            self.transitions = NavigationTransition.defaultTransitions
        }
    }

    public var body: some View {
        let showRoot = navViewModel.currentView == nil
        let navigationType = navViewModel.navigationType

        return ZStack {
            Group {
                if showRoot {
                    rootView
                        .id(rootViewID)
                        .transition(navigationType == .push ? transitions.push : transitions.pop)
                        .environmentObject(navViewModel)
                } else {
                    navViewModel.currentView!.wrappedElement
                        .id(navViewModel.currentView!.id)
                        .transition(navigationType == .push ? transitions.push : transitions.pop)
                        .environmentObject(navViewModel)
                }
            }
        }
    }
}

/// A view used to navigate to another view through its enclosing NavigationStack.
public struct PushView<Label, Destination, Tag>: View where Label: View, Destination: View, Tag: Hashable {
    @EnvironmentObject private var navViewModel: NavigationStack
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
    public init(destination: Destination, destinationId: String? = nil, tag: Tag, selection: Binding<Tag?>,
         @ViewBuilder label: () -> Label) {
        self.init(destination: destination, destinationId: destinationId, isActive: Binding.constant(false),
                  tag: tag, selection: selection, label: label)
    }

    private init(destination: Destination, destinationId: String?, isActive: Binding<Bool>,
                 tag: Tag?, selection: Binding<Tag?>, @ViewBuilder label: () -> Label) {
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
                self.push()
            }
        }
        if isActive {
            DispatchQueue.main.async {
                self.isActive = false
                self.push()
            }
        }
        return label.onTapGesture {
            self.push()
        }
    }

    private func push() {
        self.navViewModel.push(self.destination, withId: self.destinationId)
    }
}

public extension PushView where Tag == Never {

    /// Creates a PushView that triggers the navigation on tap.
    /// - Parameters:
    ///   - destination: The view to navigate to.
    ///   - destinationId: The ID of the destination view (used to easily come back to it if needed).
    ///   - label: The actual view to tap to trigger the navigation.
    init(destination: Destination, destinationId: String? = nil, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, destinationId: destinationId, isActive: Binding.constant(false),
                  tag: nil, selection: Binding.constant(nil), label: label)
    }

    /// Creates a PushView that triggers the navigation on tap or when a boolean value becomes true.
    /// - Parameters:
    ///   - destination: The view to navigate to.
    ///   - destinationId: The ID of the destination view (used to easily come back to it if needed).
    ///   - isActive: A boolean binding that triggers the navigation if and when becomes true.
    ///   - label: The actual view to tap to trigger the navigation.
    init(destination: Destination, destinationId: String? = nil,
         isActive: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, destinationId: destinationId, isActive: isActive,
                  tag: nil, selection: Binding.constant(nil), label: label)
    }
}

/// A view used to navigate back to a previous view through its enclosing NavigationStack.
public struct PopView<Label, Tag>: View where Label: View, Tag: Hashable {
    @EnvironmentObject private var navViewModel: NavigationStack
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
    public init(destination: PopDestination = .previous, tag: Tag, selection: Binding<Tag?>, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, isActive: Binding.constant(false),
                  tag: tag, selection: selection, label: label)
    }

    private init(destination: PopDestination, isActive: Binding<Bool>, tag: Tag?,
                 selection: Binding<Tag?>, @ViewBuilder label: () -> Label) {
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
                self.pop()
            }
        }
        if isActive {
            DispatchQueue.main.async {
                self.isActive = false
                self.pop()
            }
        }
        return label.onTapGesture {
            self.pop()
        }
    }

    private func pop() {
        self.navViewModel.pop(to: self.destination)
    }
}

public extension PopView where Tag == Never {

    /// Creates a PopView  that triggers the navigation on tap.
    /// - Parameters:
    ///   - destination: The destination type of the pop operation.
    ///   - label: The actual view to tap to trigger the navigation.
    init(destination: PopDestination = .previous, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, isActive: Binding.constant(false),
                  tag: nil, selection: Binding.constant(nil), label: label)
    }

    /// Creates a PopView  that triggers the navigation on tap or when a boolean value becomes true.
    /// - Parameters:
    ///   - destination: The destination type of the pop operation.
    ///   - isActive: A boolean binding that triggers the navigation if and when becomes true.
    ///   - label: The actual view to tap to trigger the navigation.
    init(destination: PopDestination = .previous, isActive: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, isActive: isActive,
                  tag: nil, selection: Binding.constant(nil), label: label)
    }
}
