//
//  NavigationStackView.swift
//  
//
//  Created by Matteo Puccinelli on 14/04/21.
//

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
        let pushTrans = AnyTransition.asymmetric(insertion: .move(edge: .trailing),
                                                 removal: .move(edge: .leading))
        let popTrans = AnyTransition.asymmetric(insertion: .move(edge: .leading),
                                                removal: .move(edge: .trailing))
        return (pushTrans, popTrans)
    }
}

/// An alternative SwiftUI NavigationView implementing classic stack-based navigation giving also some more control on animations and programmatic navigation.
public struct NavigationStackView<Root>: View where Root: View {
    @ObservedObject private var navigationStack: NavigationStack
    private let rootView: Root
    private let transitions: (push: AnyTransition, pop: AnyTransition)

    /// Creates a NavigationStackView.
    /// - Parameters:
    ///   - transitionType: The type of transition to apply between views in every push and pop operation.
    ///   - easing: The easing function to apply to every push and pop operation.
    ///   - rootView: The very first view in the NavigationStack.
    public init(transitionType: NavigationTransition = .default,
                easing: Animation = NavigationStack.defaultEasing,
                @ViewBuilder rootView: () -> Root) {

        self.init(transitionType: transitionType,
                  navigationStack: NavigationStack(easing: easing),
                  rootView: rootView)
    }

    /// Creates a NavigationStackView with the provided NavigationStack
    /// - Parameters:
    ///   - transitionType: The type of transition to apply between views in every push and pop operation.
    ///   - navigationStack: the shared NavigationStack
    ///   - rootView: The very first view in the NavigationStack.
    public init(transitionType: NavigationTransition = .default,
                navigationStack: NavigationStack,
                @ViewBuilder rootView: () -> Root) {

        self.rootView = rootView()
        self.navigationStack = navigationStack
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
        let showRoot = navigationStack.currentView == nil
        let navigationType = navigationStack.navigationType

        return ZStack {
            Group {
                if showRoot {
                    rootView
                        .transition(navigationType == .push ? transitions.push : transitions.pop)
                        .environmentObject(navigationStack)
                } else {
                    navigationStack.currentView!.wrappedElement
                        .transition(navigationType == .push ? transitions.push : transitions.pop)
                        .environmentObject(navigationStack)
                }
            }
        }
    }
}
