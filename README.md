# swiftui-navigation-stack
An alternative SwiftUI NavigationView implementing classic stack-based navigation giving also some more control on animations and programmatic navigation.

# NavigationStackView

## Installation

Through [SwiftPackageManager](https://swift.org/package-manager/): open xCode, click on `File -> Swift Packages -> Add Package dependency...` and use the repository URL (https://github.com/biobeats/swiftui-navigation-stack.git) to download the package.

In xCode, when prompted for Version or branch, the suggestion is to use Branch: master.

Then in your View simply include `import NavigationStack` and follow usage examples below.

## Usage

In SwiftUI we have a couple of views to manage the navigation: `NavigationView` and `NavigationLink`. At the moment these views have some limitations:

- we can't turn off the transition animations;
- we can't customise the transition animations;
- we can't navigate back either to root (i.e. the first app view), or to a specific view;
- we can't push programmatically without using a view;

`NavigationStackView` is a view that mimics all the behaviours belonging to the standard `NavigationView`, but it adds the features listed here above. You have to wrap your view hierarchy inside a `NavigationStackView`:

```
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

```
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

**Note:** If you want to specify a different transition for push and pop, you can use `.asymmetric`

```
import NavigationStack

struct RootView: View {
    var body: some View {
        NavigationStackView(transitionType: .custom(.asymmetric(insertion: .opacity, removal: .scale))) {
            MyHome()
        }
    }
}
```

## Push

In order to navigate forward you have two options: 

- Using the `PushView`;
- Programmatically push accessing the navigation stack directly;

### PushView

The basic usage of `PushView` is:

```
PushView(destination: ChildView()) {
    Text("PUSH")
}
```

which creates a tappable view (in this case a simple `Text`) to navigate to a destination. There are other ways to trigger the navigation using the `PushView`:

```
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

```
enum ViewDestinations {
    case noDestination
    case child1
    case child2
    case child3
}

struct MyHome: View {
    @ObservedObject private var viewModel = ViewModel()
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

```
struct MyHome: View {
    @ObservedObject private var viewModel = ViewModel()
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

```
struct MyHome: View {
    private static let childID = "childID"
    @ObservedObject private var viewModel = ViewModel()
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

```
struct ChildView: View {
    var body: some View {
        PopView {
            Text("POP")
        }        
    }
}
```

which pops to the previous view. You can even specify a destination for your pop operation:

```
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

```
struct ChildView: View {
    @ObservedObject private var viewModel = ViewModel()
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

## Important

Please, note that `NavigationStackView` navigates between views and two views may be smaller than the entire screen. In that case the transition animation won't involve the whole screen, but just the two views. Let's make an example:

```
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

```
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

```
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

There are several issues at the moment:

- during the `NavigationStackView` initialisation you can attach animations to your transitions to override the default navigation stack animation. For instance:

```
NavigationStackView(transitionType: .custom(AnyTransition.scale.animation(.spring()))) {
    Home()
}
```

this feature is not working with some kind of transitions (for example the `.move` transition). In this case the animation you'll get is the `NavigationStackView` default animation (an easy out that lasts 0.2s) which is specified in the implementation (in the `NavigationStack` class) through an explicit `withAnimation` block. At the moment it seems that some transitions can work only with explicit animations defined by the `withAnimation` block. It's very likely a SwiftUI bug;

- SwiftUI resets all the properties of a view marked with `@State` every time the view is removed from a view hierarchy. For the `NavigationStackView` this is a problem because when I come back to a previous view (with a pop operation) I want all my view controls to be as I left them before (for example I want my `TextField`s to contain the text I previously typed in). It seems that the solution to this problem is using the `.id` modifier specifying an id for the views I don't want SwiftUI to reset. According to the Apple documentation the `.id` modifier:

> Summary
> Generates a uniquely identified view that can be inserted or removed.

but again, it seems that this API is currently not working as expected (take a look at this interesting post: https://swiftui-lab.com/swiftui-id/). In order to workaround this problem, then, you have to use `@ObservableObject` when you need to make some state persist between push/pop operations. For example:

```
class ViewModel: ObservableObject {
    @Published var text = ""
}

struct MyView: View {
    @ObservedObject var viewModel = ViewModel()
    
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

SwiftUI is really new, there are some bugs in the framework (or unexpected behaviours) and several API not yet documented. Please, report any issue may arise and feel free to suggest any improvement or changing to this first implementation of a navigation stack.
 


