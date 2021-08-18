# swiftui-navigation-stack
An alternative SwiftUI NavigationView implementing classic stack-based navigation giving also some more control on animations and programmatic navigation.

# NavigationStack

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler: open xCode, click on `File -> Swift Packages -> Add Package dependency...` and use the repository URL (https://github.com/matteopuc/swiftui-navigation-stack.git) to download the package.

In xCode, when prompted for Version or branch, the suggestion is to use Branch: master.

Then in your View simply include `import NavigationStack` and follow usage examples below.

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate NavigationStack into your Xcode project using CocoaPods, specify it in your `Podfile`:

```swift
pod 'NavigationStack'
```

Then in your View simply include `import NavigationStack` and follow usage examples below.

## Usage

In SwiftUI we have a couple of views to manage the navigation: `NavigationView` and `NavigationLink`. At the moment these views have some limitations:

- we can't turn off the transition animations;
- we can't customise the transition animations;
- we can't navigate back either to root (i.e. the first app view), or to a specific view;
- we can't push programmatically without using a view;

`NavigationStackView` is a view that mimics all the behaviours belonging to the standard `NavigationView`, but it adds the features listed here above. You have to wrap your view hierarchy inside a `NavigationStackView`:

```swift
import NavigationStack

struct RootView: View {
    var body: some View {
        NavigationStackView {
            MyHome()
        }
    }
}
```

![Jan-07-2020 15-40-35](https://user-images.githubusercontent.com/5569047/71903303-12cae980-3164-11ea-939e-f2abcd869484.gif)

You can even customise transitions and animations in some different ways. The `NavigationStackView` will apply them to the hierarchy: 

- you could decide to go for no transition at all by creating the navigation stack this way `NavigationStackView(transitionType: .none)`;
- you could create the navigation stack with a custom transition:

```swift
import NavigationStack

struct RootView: View {
    var body: some View {
        NavigationStackView(transitionType: .custom(.scale)) {
            MyHome()
        }
    }
}
```

![Jan-10-2020 15-31-40](https://user-images.githubusercontent.com/5569047/72160405-9718a900-33be-11ea-8b78-6bcbbf4283d7.gif)

- `NavigationStackView` has a default easing for transitions. The easing can be customised during the initialisation
```swift
struct RootView: View {
    var body: some View {
        NavigationStackView(transitionType: .custom(.scale), easing: .spring(response: 0.5, dampingFraction: 0.25, blendDuration: 0.5)) {
            MyHome()
        }
    }
}
```
**Important:** The above is the recommended way to customise the easing function for your transitions. Please, note that you could even specify the easing this other way:

```swift
NavigationStackView(transitionType: .custom(AnyTransition.scale.animation(.spring(response: 0.5, dampingFraction: 0.25, blendDuration: 0.5))))
```

attaching the easing directly to the transition. **Don't do this**. SwiftUI has still some problems with implicit animations attached to transitions, so it may not work. For example, implicit animations attached to a .slide transition won't work.

## Push

In order to navigate forward you have two options: 

- Using the `PushView`;
- Programmatically push accessing the navigation stack directly;

### PushView

The basic usage of `PushView` is:

```swift
PushView(destination: ChildView()) {
    Text("PUSH")
}
```

which creates a tappable view (in this case a simple `Text`) to navigate to a destination. There are other ways to trigger the navigation using the `PushView`:

```swift
struct MyHome: View {
    @State private var isActive = false
    
    var body: some View {
        VStack {
            PushView(destination: ChildView(), isActive: $isActive) {
                Text("PUSH")
            }
            
            Button(action: {
                self.isActive.toggle()
            }, label: {
                Text("Trigger push")
            })
        }
    }
}
```

this way you have a tappable view as before, but you can even exploit the `isActive` bool to trigger the navigation (also in this case the navigation is triggered through the `PushView`).

If you have several destinations and you want to avoid having a lot of `@State` booleans you can use this other method:

```swift
enum ViewDestinations {
    case noDestination
    case child1
    case child2
    case child3
}

struct MyHome: View {
    @ObservedObject var viewModel: ViewModel
    @State private var isSelected: ViewDestinations? = .noDestination

    var body: some View {
        VStack {
            PushView(destination: ChildView1(), tag: ViewDestinations.child1, selection: $isSelected) {
                Text("PUSH TO CHILD 1")
            }

            PushView(destination: ChildView2(), tag: ViewDestinations.child2, selection: $isSelected) {
                Text("PUSH TO CHILD 2")
            }

            PushView(destination: ChildView3(), tag: ViewDestinations.child3, selection: $isSelected) {
                Text("PUSH TO CHILD 3")
            }

            Button(action: {
                self.isSelected = self.viewModel.getDestination()
            }, label: {
                Text("Trigger push")
            })
        }
    }
}
```

Now you have three tappable views and the chance to trigger the navigation through a `tag` (the navigation is always triggered by the `PushView`).

### Push programmatically:

Inside the `NavigationStackView` you have access to the navigation stack as an `EnvironmentObject`. If you need to trigger the navigation programmatically without relying on a `PushView` (i.e. without having a tappable view) you can do like this:

```swift
struct MyHome: View {
    @ObservedObject var viewModel: ViewModel
    @EnvironmentObject private var navigationStack: NavigationStack

    var body: some View {
        Button(action: {
            self.viewModel.performBackgroundActivities(withCallback: {
                DispatchQueue.main.async {
                    self.navigationStack.push(ChildView())
                }
            })
        }, label: {
            Text("START BG ACTIVITY")
        })
    }
}
```

## Specifying an ID 

It's not mandatory, but if you want to come back to a specific view at some point later you need to specify an ID for that view. Both `PushView` and programmatic push allow you to do that:

```swift
struct MyHome: View {
    private static let childID = "childID"
    @ObservedObject var viewModel: ViewModel
    @EnvironmentObject private var navigationStack: NavigationStack

    var body: some View {
        VStack {
            PushView(destination: ChildView(), destinationId: Self.childID) {
                Text("PUSH")
            }
            Button(action: {
                self.viewModel.performBackgroundActivities(withCallback: {
                    DispatchQueue.main.async {
                        self.navigationStack.push(ChildView(), withId: Self.childID)
                    }
                })
            }, label: {
                Text("START BG ACTIVITY")
            })
        }
    }
}
```

## Pop

Pop operation works as the push operation. We have the same two options:

- Using the `PopView`;
- Programmatically pop accessing the navigation stack directly;

### PopView

The basic usage of `PopView` is: 

```swift
struct ChildView: View {
    var body: some View {
        PopView {
            Text("POP")
        }        
    }
}
```

which pops to the previous view. You can even specify a destination for your pop operation:

```swift
struct ChildView: View {
    var body: some View {
        VStack {
            PopView(destination: .root) {
                Text("POP TO ROOT")
            }
            PopView(destination: .view(withId: "aViewId")) {
                Text("POP TO THE SPECIFIED VIEW")
            }
            PopView {
                Text("POP")
            }
        }
    }
}
```

`PopView` has the same features as the `PushView`. You can create a `PopView` that triggers with the `isActive` bool or with the `tag`. Also, you can trigger the navigation programmatically without relying on the `PopView` itself, but accessing the navigation stack directly:

```swift
struct ChildView: View {
    @ObservedObject var viewModel: ViewModel
    @EnvironmentObject private var navigationStack: NavigationStack

    var body: some View {
        Button(action: {
            self.viewModel.performBackgroundActivities(withCallback: {
                self.navigationStack.pop()
            })
        }, label: {
            Text("START BG ACTIVITY")
        })
    }
}
```

## NavigationStack injection

By default you can programmatically push and pop only inside the `NavigationStackView` hierarchy (by accessing the `NavigationStack` environment object). If you want to use the `NavigationStack` outside the `NavigationStackView` you need to create your own `NavigationStack` (wherever you want) **and pass it as a parameter to the `NavigationStackView`**. This is useful when you want to decouple your routing logic from views.

**Important:** Every `NavigationStack` must be associated to a `NavigationStackView`. A `NavigationStack` cannot be shared between multiple `NavigationStackView`.

For example:

```swift
struct RootView: View {
    let navigationStack: NavigationStack

    var body: some View {
        NavigationStackView(navigationStack: navigationStack) {
            HomeScreen(router: MyRouter(navStack: navigationStack))
        }
    }
}

class MyRouter {
    private let navStack: NavigationStack

    init(navStack: NavigationStack) {
        self.navStack = navStack
    }

    func toLogin() {
        self.navStack.push(LoginScreen())
    }

    func toSignUp() {
        self.navStack.push(SignUpScreen())
    }
}

struct HomeScreen: View {
    let router: MyRouter

    var body: some View {
        VStack {
            Text("Home")
            Button("To Login") {
                router.toLogin()
            }
            Button("To SignUp") {
                router.toSignUp()
            }
        }
    }
}
```

## Important

Please, note that `NavigationStackView` navigates between views and two views may be smaller than the entire screen. In that case the transition animation won't involve the whole screen, but just the two views. Let's make an example:

```swift
struct Root: View {
    var body: some View {
        NavigationStackView {
            A()
        }
    }
}

struct A: View {
    var body: some View {
        VStack(spacing: 50) {
            Text("Hello World")
            PushView(destination: B()) {
                Text("PUSH")
            }
        }
        .background(Color.green)
    }
}

struct B: View {
    var body: some View {
        PopView {
            Text("POP")
        }
        .background(Color.yellow)
    }
}
```

The result is:

![Jan-10-2020 15-47-43](https://user-images.githubusercontent.com/5569047/72161560-a0a31080-33c0-11ea-8194-d6cb126953f4.gif)

The transition animation uses just the minimum amount of space necessary for the views to enter/exit the screen (i.e. in this case the maximum width between view1 and view2) and this is exactly how it is meant to be.

On the other hand you also probably want to use the `NavgationStackView` to navigate screens. Since in SwiftUI a screen (the old UIKit `ViewController`) it's just a `View` I suggest you create an handy and simple custom view called `Screen` like this:

```swift
extension Color {
    static let myAppBgColor = Color.white
}

struct Screen<Content>: View where Content: View {
    let content: () -> Content

    var body: some View {
        ZStack {
            Color.myAppBgColor.edgesIgnoringSafeArea(.all)
            content()
        }
    }
}
```

Now we can rewrite the example above using the `Screen` view:

```swift
struct Root: View {
    var body: some View {
        NavigationStackView {
            A()
        }
    }
}

struct A: View {
    var body: some View {
        Screen {
            VStack(spacing: 50) {
                Text("Hello World")
                PushView(destination: B()) {
                    Text("PUSH")
                }
            }
            .background(Color.green)
        }
    }
}

struct B: View {
    var body: some View {
        Screen {
            PopView {
                Text("POP")
            }
            .background(Color.yellow)
        }
    }
}
```

This time the transition animation involves the whole screen:

![Jan-10-2020 16-10-59](https://user-images.githubusercontent.com/5569047/72163299-deedff00-33c3-11ea-935f-ce4341afe201.gif)

## Issues

- SwiftUI resets all the properties of a view marked with `@State` every time the view is removed from a view hierarchy. For the `NavigationStackView` this is a problem because when I come back to a previous view (with a pop operation) I want all my view controls to be as I left them before (for example I want my `TextField`s to contain the text I previously typed in). In order to workaround this problem you have to use `@ObservableObject` when you need to make some state persist between push/pop operations. For example:

```swift
class ViewModel: ObservableObject {
    @Published var text = ""
}

struct MyView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack {
            TextField("Type something...", text: $viewModel.text)
            PushView(destination: MyView2()) {
                Text("PUSH")
            }
        }
    }
}
```

### Other

SwiftUI is really new, there are some unexpected behaviours and several API not yet documented. Please, report any issue may arise and feel free to suggest any improvement or changing to this implementation of a navigation stack.
