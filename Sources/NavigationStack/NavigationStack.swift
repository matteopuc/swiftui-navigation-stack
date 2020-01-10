//
//  NavigationStack.swift
//
//  Created by Matteo Puccinelli on 28/11/2019.

import SwiftUI

/// The transition type for the whole NavigationStackView
enum NavigationTransition {
    case none
    case `default`
    case custom(AnyTransition)

    fileprivate static var defaultTransitions: (push: AnyTransition, pop: AnyTransition) {
        let pushTrans = AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        let popTrans = AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        return (pushTrans, popTrans)
    }

    fileprivate static var defaultEasing: Animation {
        .easeOut(duration: 0.2)
    }
}

private enum NavigationType {
    case push
    case pop
}

enum PopDestination {
    case previous
    case root
    case view(withId: String)
}

enum NavigationStackError: Error {
    case duplicatedViewId
    case viewNotFound
}

// MARK: ViewModel

class NavigationStack: ObservableObject {
    fileprivate private(set) var navigationType = NavigationType.push
    private var viewStack = ViewStack() {
        didSet {
            currentView = viewStack.peek()
        }
    }

    @Published fileprivate var currentView: ViewElement?

    func push<Element: View>(_ element: Element, withId identifier: String? = nil) {
        withAnimation(NavigationTransition.defaultEasing) {
            navigationType = .push
            viewStack.push(ViewElement(id: identifier == nil ? UUID().uuidString : identifier!,
                                       wrappedElement: AnyView(element)))
        }
    }

    func pop(to: PopDestination = .previous) {
        withAnimation(NavigationTransition.defaultEasing) {
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
            if indexForView(withId: element.id) != nil {
                return
            }
            views.append(element)
        }

        mutating func popToPrevious() {
            _ = views.popLast()
        }

        mutating func popToView(withId identifier: String) {
            guard let viewIndex = indexForView(withId: identifier) else {
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

struct NavigationStackView<Root>: View where Root: View {
    @ObservedObject private var navViewModel = NavigationStack()
    private let rootViewID = "root"
    private let rootView: Root
    private let transitions: (push: AnyTransition, pop: AnyTransition)

    init(transitionType: NavigationTransition = .default, @ViewBuilder rootView: () -> Root) {
        self.rootView = rootView()
        switch transitionType {
        case .none:
            self.transitions = (.identity, .identity)
        case .custom(let trans):
            self.transitions = (trans, trans)
        default:
            self.transitions = NavigationTransition.defaultTransitions
        }
    }

    var body: some View {
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

struct PushView<Label, Destination, Tag>: View where Label: View, Destination: View, Tag: Hashable {
    @EnvironmentObject private var navViewModel: NavigationStack
    private let label: Label?
    private let destinationId: String?
    private let destination: Destination
    private let tag: Tag?
    @Binding var isActive: Bool
    @Binding var selection: Tag?

    init(destination: Destination, destinationId: String? = nil, tag: Tag, selection: Binding<Tag?>,
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

    var body: some View {
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

extension PushView where Tag == Never {
    init(destination: Destination, destinationId: String? = nil, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, destinationId: destinationId, isActive: Binding.constant(false),
                  tag: nil, selection: Binding.constant(nil), label: label)
    }

    init(destination: Destination, destinationId: String? = nil,
         isActive: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, destinationId: destinationId, isActive: isActive,
                  tag: nil, selection: Binding.constant(nil), label: label)
    }
}

struct PopView<Label, Tag>: View where Label: View, Tag: Hashable {
    @EnvironmentObject private var navViewModel: NavigationStack
    private let label: Label
    private let destination: PopDestination
    private let tag: Tag?
    @Binding var isActive: Bool
    @Binding var selection: Tag?

    init(destination: PopDestination = .previous, tag: Tag, selection: Binding<Tag?>, @ViewBuilder label: () -> Label) {
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

    var body: some View {
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

extension PopView where Tag == Never {
    init(destination: PopDestination = .previous, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, isActive: Binding.constant(false),
                  tag: nil, selection: Binding.constant(nil), label: label)
    }

    init(destination: PopDestination = .previous, isActive: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.init(destination: destination, isActive: isActive,
                  tag: nil, selection: Binding.constant(nil), label: label)
    }
}
