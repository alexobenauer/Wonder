# Workbench

*Personal interfaces dev kit*

---

With Workbench, you can build and use your own personal, itemized interfaces like the ones in my experiments ([Tag Navigator](https://alexanderobenauer.com/labnotes/exp001/), and [OLLOS](https://alexanderobenauer.com/ollos/)) and [lab notes](https://alexanderobenauer.com/labnotes/000/).

Workbench runs as a native app on Apple devices, and syncs data automatically via iCloud.

In it, you can build *providers*, which bring items into your item store from external sources, and *apps*, which are the interfaces you'd like to use with your items — creating, reviewing, and modifying them. You can also build new *item views*, for new and existing item types, which are provided to existing apps and other views (this is a simple way to extend interfaces in Workbench and to add new functionality to existing items and views).

Workbench comes with some starter providers and apps that you can use or modify. If you build something cool, send a pull request — more providers, apps, and item views help show what's possible in Workbench. 

This document guides you through building your own personal software in Workbench on top of its item store.


## Items & the item store

In Workbench, items are stored as lists of facts. Each fact has an item ID, attribute, value, and timestamp. (Each fact also has a fact ID, value type, numerical value, and removed flag, but you usually don't need to worry about these.)

### Insert facts

You can insert facts like so:

```Swift
ItemStore.shared.insert(fact: Fact(
    itemId: "1", 
    attribute: "title", 
    value: .string("Hello, world!")
))
```

Whenever you have multiple facts to insert, you should always insert them together:

```Swift
ItemStore.shared.insert(facts: [
    Fact(
        itemId: "1", 
        attribute: "type", 
        value: .string("note")
    ),
    Fact(
        itemId: "1", 
        attribute: "title", 
        value: .string("Hello, world!")
    )
])
```

This is more efficient, because interfaces only receive one update notification; and it is more correct, because these items are given the same timestamp, which is considered by some apps when grouping facts to describe changes over time.

### Create items

The item store provides some helper functions for common operations which handle lots of little expectations that apps can rely on.

For example, you should use this function whenever you create a new item:

```Swift
ItemStore.shared.createItem(
    type: "note",
    attributes: [
        "title": .string("Hello, world!")
    ]
)
```

This function inserts a handful of facts needed to "create" an item: it ensures that there's a "created" fact for new items which apps can rely on, and it ensures you provide a type for each item, which helps Workbench find the right item views in apps that don't do custom rendering for items (more on that later).

This function also has some optional parameters that can help creating items with lots of detail more concise.

### Relate items

You can use this function whenever you want to create a relationship between two items:

```Swift
ItemStore.shared.relateItems(
    fromItemId: "1",
    toItemId: "2",
    referenceType: "content",
    referenceAttributes: [
        "order": .number(0)
    ]
)
```

This function inserts all the facts needed for a "relationship" item, which describes the relationship between two items. This lets us make a graph of items — we can now have a "list" item with "todo" items in it, or we can build full-fledged PKM apps.

And by the way, the `createItem` function has parameters for setting up relationships when creating items.

Also, both of these function provide static counterparts on `ItemStore` that just provide the facts that are inserted when the above functions are called. These can be useful when you need to insert other facts at the same time.

### Fetch facts

There are a few ways to fetch facts. Using this function:

```Swift
func fetchFacts(
    itemId: String? = nil,
    attribute: String? = nil,
    value: String? = nil,
    includeDeleted: Bool = false,
    resource: String? = nil
) -> [Fact]
```

You can provide any combination of the parameters to the `fetchFacts` function:

```Swift
var facts: [Fact];

// Get all facts for one item
facts = ItemStore.shared.fetchFacts(itemId: "1")

// Get an item's type
facts = ItemStore.shared.fetchFacts(itemId: "1", attribute: "type")

// Find items of a certain type
facts = ItemStore.shared.fetchFacts(attribute: "type", value: "note")

```

Facts are returned in an array, sorted from the most recent fact to the least. This means you can grab `facts.first` if you're looking for the most recent matching result.

Getting the value of a `Fact` is best done through its `typedValue` property:

```Swift
let title: String? = fact1.typedValue?.stringValue
let time: Date? = fact2.typedValue?.dateValue
```

There's two other functions for fetching facts.

### Fetch facts by value range

Use this function to fetch facts within a value range:

```Swift
func fetchFacts(
    itemId: String? = nil,
    attribute: String? = nil,
    valueAtOrAbove: Double,
    valueAtOrBelow: Double,
    includeDeleted: Bool = false,
    resource: String? = nil
) -> [Fact]
```

This can only be used with values that are inserted as numbers or dates.

### Fetch facts by insertion timestamp

Use this function to fetch facts that were inserted within a time range:

```Swift
func fetchFacts(
    createdAtOrAfter: Date?,
    createdAtOrBefore: Date?,
    includeDeleted: Bool = false,
    resource: String? = nil
) -> [Fact]
```

This can be helpful when assembling timelines.

### Overfetching & efficient queries

These fetch functions are intentionally basic for now. To do more complex querying, overfetch and filter in memory.

But be more specific wherever you can; interface elements only need to reload when facts they care about have new values. 

For example, fetching all of an item's facts in one view means the entire view must reload whenever the item has any new facts; fetching specific attributes for that item in subviews means each subview only needs to refresh when the attribute it renders has new values.

This becomes most important at the scale of many items: instead of fetching all the facts about all the items your view cares about in one go, push more precise fetches lower in the view tree for a performance benefit. (Of course, sometimes this is unavoidable, when lots of pre-processing needs to be done at the level of a superview.)

### Delete facts

In the item store, deleting is not erasing; it's simply inserting a new fact that describes an old one as removed. `ItemStore` provides helper functions that insert these facts for you, too:

```Swift
ItemStore.shared.deleteFact(someFact)
```

This passed-in fact will no longer be included by default when fetching facts. However, you can pass `includeDeleted: true` to have deleted facts included.

This `deleteFact` function stores facts with their "removed" flag flipped. Here's its implementation:

```Swift
func deleteFact(_ fact: Fact) {
    insert(fact: Fact(
        factId: fact.factId,
        itemId: fact.itemId,
        attribute: fact.attribute,
        value: fact.value,
        numericalValue: fact.numericalValue,
        type: fact.type,
        flags: fact.flags ^ 1,
        timestamp: Date()
    ))
}
```

This means you can "delete" a "deletion" fact to undo its effect.

### Delete items

You can also delete whole items like so:

```Swift
ItemStore.shared.deleteItem(itemId: "1")
```

This is more storage efficient and more correct than deleting all of the facts that describe an item because the item store internally handles only storing one fact that describes the item as deleted, and provides the appropriate "deleted" facts at runtime. This is more correct than deleting all known facts about an item manually since older facts about the item might sync from another device later, and would not be marked as deleted as expected. By calling `deleteItem`, the item store takes care of this edge case for you.

You can also provide a successor item when deleting an item:

```Swift
ItemStore.shared.deleteItem(itemId: "1", successorItemId: "2")
```

This creates a relationship item between the deleted item and the successor item. This can be helpful to describe your item graph's connections more completely (e.g. a "draft" email item, when deleted, is often succeeded by its "sent" counterpart).


### Item drives

**This is very important:** when calling the functions mentioned above, facts are stored in iCloud and synced to all of your devices. This is probably not what you want to do in many kinds of providers, and it's certainly not what you want to do during initial development.

Instead, mount an in-memory resource drive to use.

**Mount & use a resource drive:** Here's how you mount a new resource drive, which you must do before attempting to use it:

```Swift
ItemStore.shared.mountDrive(forResource: "calendar-events", inMemory: true)
```

Now, whenever you call a function that inserts facts, provide the same identifier, like so:

```Swift
ItemStore.shared.insert(fact: fact, resource: "calendar-events")
```

**More about item drives**

The item store is made up of *item drives,* which each store a subset of the facts. There are a couple item drive implementations in Workbench: one that uses a local SQLite database on disk or in memory, and another that uses CoreData.

There is a *user drive* where facts about items the user creates are stored. In Workbench, this drive uses the CoreData implementation and syncs using CloudKit.

Then there are *resource drives* where most facts from providers belong. These drives use the SQLite implementation, and some providers use these in-memory when their contents need to be wholesale imported at runtime (more on this later).

If you don't provide a resource identifier when inserting facts (using any of the functions that do so), your fact will be inserted into the user drive, and in Workbench, ~irreversibly synced via iCloud.

Instead, during initial development, and in most providers, you should use a resource drive. This lets you store the database in memory or delete the resulting SQLite database whenever you're done with it.

Every function that inserts facts has an optional "resource" parameter that your providers should almost always use. (Functions that fetch facts also have a "resource" parameter that can be provided to make fetching more efficient.)

**Creating new drive implementations** 

You can create your own drive implementation with its own storage, syncing, or querying strategy if you'd like. It just needs to conform to the `ItemDrive` protocol which requires only the basic fact functions.


## Building new things in Workbench

Workbench doesn't enforce any particular protocol. When you want to interact with the item store, you simply call the above functions. You can technically build anything you want, in any way you want.

However, it's helpful to think of two primary types of things you might add to Workbench: providers and apps. (There are some others we'll cover, like default item views, which can be a helpful way to extend your system by supplying new interfaces to be used in existing apps.)

## Providers

Providers bring items from external soruces into your item store.

Whenever they vend many items, such as a list of the events on your calendar, providers should store all of their items in a resource drive.

To add a new provider, create a new file in Workbench/Providers. Here's a starter:

```Swift
import SwiftUI

class YourProvider: ObservableObject {
    let resourceId = "your-things"
    
    // Things you need in your settings view:
    @Published var authStatus: AuthorizationStatus? = nil
    @Published var lastError: String? = nil
    
    init() {
        ItemStore.shared.mountDrive(forResource: resourceId)
        
        // other initialization code here...
    }  
}

struct YourProviderSettings: View {
    @ObservedObject var yourProvider: YourProvider
    
    func onAppear() {
        yourProvider.checkAuthStatus()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Your Provider").font(.title).padding(.bottom, 2)
                Text("Description of your provider").padding(.bottom, 24)
                
                // Settings controls here...
            }
            .padding()
        }
        .onAppear(perform: onAppear)
    }
}
```

In `YourProvider`, you'll handle fetching data and inserting facts into the item store. In `YourProviderSettings`, you provide controls for modifying the provider at runtime.

Next, add your new provider to `Workbench/ContentView.swift`:

```Swift
struct ContentView: View {
    let eventsProvider = EventsProvider()
    let yourProvider = YourProvider()
    
    var providers: [String: any View] {[
        "Events": EventsProviderSettings(eventsProvider: eventsProvider),
        "Your display title": YourProviderSettings(yourProvider: yourProvider)
    ]}
    
    ...
}
```

That's all you need to do to add a new provider! Now you'll implement your new provider in `YourProvider` by using the item store's functions to insert facts.

See the existing providers in `Workbench/Providers` for example implementations.

Here are some considerations:

### Use resource drives

Providers should use resource drives, as described above. For example, in `EventsProvider`, we fetch the calendar events using the system's EventKit API. We don't want or need to store this data in the synced, on-disk user drive; this data is already stored locally! Instead, our provider uses an in-memory resource drive in the item store to store its facts.

There are times when providers should store items in the user drive, and that's generally when we've manually requested or saved a specific item during use. E.g. when requesting a weather forecast for our current location, or when saving an email to a specific location in our graph (the email provider keeps incoming emails in an in-memory resource drive, but can save an email to the user drive when we want to pin it into our timeline, or use it in other kinds of organizations within our item graph).

### In-memory drives

Most of the external world doesn't think in terms of facts about items. When an API doesn't let you get this kind of granular information, you'll have to consider your syncing strategy: how will you update the item store when changes happen, based on how your external source provides data?

For example, in `EventsProvider`, you'll see that we get the local device's calendar events and insert them into an in-memory resource drive. Why is it in memory? Because we only get events from the EventKit API in big heaps, filtered down only by calendar and date/time. There's no way to get "changes" like we'd write them in the fact store. Rather than diffing what comes in against the existing data in the event provider's resource drive, which would also be a valid strategy, whenever there's an update from the EventKit API, the in-memory database is simply cleared and re-filled.


## Apps

All of the above material is to get here: we now have the ability to build and iterate on the interfaces we use to create, review, and modify our items.

To add a new app, create a new file in `Workbench/Apps`. Here's a starter:

```Swift
import SwiftUI

struct YourApp: View {
    var body: some View {
        ScrollView {
            VStack {
                // your interface elements here...
            }
            .frame(maxWidth: 650, alignment: .center)
            .padding()
            
            HStack {
                Spacer()
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    YourApp()
}
```

Next, add your new app to the `apps` dictionary in `Workbench/ContentView.swift`:

```Swift
var apps: [String: any View] {[
    "Agenda": Agenda(),
    "Your App Name": App()
]}
```

That's all you need to get started. Now you can implement your app in `YourApp.swift`. You can use the item store's basic functions for inserting and fetching facts, but there are also some pre-made components to help you get started.

Note that when using SwiftUI, things are more performant when you break your views into subviews. This is especially true when using the item store, because only the subviews with new query results need to be reloaded when facts are added.

### Subscribers

In order to have updates to your queries automatically re-render the views that depend on them, the item store providers `ItemStoreSubscriber`, and some generic implementations that make things easy.

Here we use `SimpleItemStoreSubscriber`, an implementation that lets us provide our item store query as a function that will automatically be re-called any time new facts are available:

```Swift
import SwiftUI

struct TextView: View {
    @StateObject private var text = SimpleItemStoreSubscriber(initialValue: nil as String?)
    
    var body: some View {
        Text(text.value ?? "")
            .onAppear {
                text.initialize {
                    ItemStore.shared.fetchFacts(
                        itemId: "1",
                        attribute: "title"
                    ).first?.typedValue?.stringValue
                }
            }
    }
}
```

Note that you likely won't hardcode item IDs.

This view depends on the result of a `fetchFacts` query, and will be re-rendered whenever it changes.



You can also implement your own `ItemStoreSubscriber` to get better performance in more complex situations. 

In the above example, the `fetchFacts` call has to be re-run every time the item store has updates in order to see if the view needs to be re-rendered with new data.

When this isn't performant, we can implement our own `ItemStoreSubscriber`. An example of this can be seen in `Workbench/Apps/Timeline.swift`, where our timeline view creates `ActivityListSubscriber`.

Here's a starter implementation of an `ItemStoreSubscriber` and a view that will use it:

```Swift
class CustomSubscriber: ItemStoreSubscriber, ObservableObject {
    init(/*params*/) {
        self.unsubscribe = ItemStore.shared.subscribeToNewFacts(self)
        
        reload()
    }
    
    deinit {
        unsubscribe?()
    }
    
    private var unsubscribe: (() -> Void)? = nil
    
    @Published var somethingTheViewNeeds: [Something] = []
    
    func newFacts(_ facts: [Fact]) {
        // This function receives every batch of new facts in the item stire
        // Use it to modify your data published for your view, or to determine if a full refresh of the data is needed using the standard `fetchFacts` functions
    }
}

fileprivate struct YourView: View {
    @StateObject private var subscriber: CustomSubscriber
    
    init(/*params*/) {
        self._subscriber = StateObject(wrappedValue: CustomSubscriber(/*params*/))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(somethingTheViewNeeds) { something in
                SomeOtherView(something: something)
            }
        }
    }
}
```

Implementations of `ItemStoreSubscriber` have to subscribe to, and unsubscribe from, the item store's changes.

The `newFacts` function is where the magic starts: this function is called every time the item store has a new batch of facts. This function can use that new batch of facts to update the data that the view needs (which can be done either by running `fetchFacts` functions again, or modifying the data based on just the new facts that have been provided).

### View components

Workbench provides shared view components which internally handle all of the subscriptions they need. This makes it easy to get started: you could build initial interfaces with pre-made view components, and only replace them as needed.

Some view components are basic, only needing to be provided with an item ID and an attribute that they'll use on that item to store their state. For example:

```Swift
struct TodoItemView: View {
    let itemId: String

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            VCCheckbox(itemId: itemId, attribute: "complete")
            VCText(itemId: itemId, attribute: "title")
        }
    }
}
```

The view components `VCCheckbox` and `VCTextInput` are used. They handle all the interactions with the item store internally, subscribing to the fact that they'll use to store their state, and submitting new facts when the user interacts with them.

These kinds of basic, one-attribute view components start with `VC` at the beginning of their names, which makes lookup easy while developing views.

You can create new view components in `Workbench/Shared/View Components`, which makes sharing common interface elements among many apps and views easier.

Some view components are bigger, handling many attributes of an item, or even the relationships between an item and others.

For example, `RefList` is provided with a `fromItemId`, and displays a modifiable outliner of the item's outgoing relationships (or "child items").

It does so using default item views for each type of item it finds. 

Another example is `RefCanvas` which lays out child items in a 2D canvas, and correctly stores the positions in the relationship item. It also uses the default item views for each type of item it finds.

Check out the other view components provided in `Workbench/Shared/View Components` — you often only need to provide an item ID, and let the view component do the rest. 

### Item views

Many view components and apps use `ItemView`, which automatically finds an appropriate default view for rendering each item, based on type.

By providing a default item view for a new kind of item, you can essentially inject that new interface into many existing views where items of your new type may appear, such as the Timeline.

To add a new item view, create a new file in `Workbench/Shared/Item Views`. In that file, create a class that conforms to the `ItemDefaults` protocol. Here's a starter:

```Swift
import SwiftUI

struct YourItemDefaults: ItemDefaults {
    static func itemView(itemId: String) -> AnyView? {
        AnyView(YourItemView(itemId: itemId))
    }
    
    static func color(itemId: String) -> Color? {
        Color(red: 217/255, green: 142/255, blue: 22/255)
    }
    
    static func updateView(fact: Fact) -> AnyView? {
        nil
    }
}

fileprivate struct YourItemView: View {
    let itemId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            VCText(itemId: itemId, attribute: "title")
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    YourItemView(itemId: "")
}
```

Then, in `Workbench/Shared/View Components/ItemView.swift`, add your class to the `itemDefaults` dictionary, with a key that matches the item type your class describes the defaults for:

```Swift
let itemDefaults: [String: ItemDefaults.Type] = [
    "note": NoteItemDefaults.self,
    "yourType": YourItemDefaults.self,
    ...
]
```

Now, your item view will be used wherever your new item type is found in views that use the item view switcher, like Folio and Timeline.

<!--
The array you created can have multiple IDs:

```Swift
case "yourType": return ["YourItemView", "AnotherItemView"]
```

This lets views make other options available at runtime, where we can switch what view we're using to render an item. The first ID provided is the default view used.

When we select a different item view, that selection is typically stored in a *relationship* item pointing from an item's parent to the item, so that this selection is context-specific. The item store provides a function that handles this automatically (`selectView`). This function also stores the last view used on the item itself so that views can use this by default in many situations.<!-- Since this selection is specific to the relationship between an item and a parent item, this selection can be handled by `RefRow` rather than `ItemView`.-->

### Apps are item views

There's a small thing to notice which has a big implications: apps can simply be big item views.

Take a look at `Workbench/Apps/Folio.swift`:

```Swift
struct Folio: View {
    var itemId: String
    
    var body: some View {
        ScrollView {
            VStack {
                PromptInput(referenceFromItemId: itemId, refType: "content")
                    .padding(.bottom)
                
                RefList(fromItemId: itemId, refType: "content", sortOrder: .reverse)
            }
            .frame(maxWidth: 650, alignment: .center)
            .padding()
            
            HStack {
                Spacer()
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
```

This app is a simple clipboard of things added to it.

It takes an `itemId` parameter, just like an item view. And in fact, that's what it is — an item view that displays any item's outgoing relationships (child items), and that lets us add new items to this list.

By taking an `itemId` parameter, instead of either hard-coding an item ID or displaying items from the entire graph, this view can be used to focus on any usbset of the graph, such as to recursively focus on items found within it (i.e. making a child item the new primary item in the view, to see its own children more easily).

At the time of this writing, the Timeline app is not written this way; instead, it looks at *all* of the items in the item store. This has nice performance benefits, as it can use simpler queries, but it means that we can't use it to look at the timeline of a subsection of our graph.

It's usually preferable to write apps that set their scope based on a root item, as is the case in Folio, rather than on type, as is somewhat the case in Timeline. This allows us more flexibility when using our apps and when managing the organization of the items in our graphs.

So, essentially, many of our apps are simply full-screen item views that we can use on any item.

### Other helpers

**`ItemStoreValue`** is a SwiftUI view that takes a function which returns a value and a function which receives that value when it is non-nil and returns another SwiftUI view. Internally, it handles subscribing to the item store and reloading when there are applicable changes. This lets you write something simple, like:

```Swift
struct VCText: View {
    let itemId: String
    let attribute: String
    var defaultText: String? = nil
    
    var body: some View {
        ItemStoreValue {
            ItemStore.shared.fetchFacts(
                itemId: itemId,
                attribute: attribute
            ).first?.typedValue?.stringValue ?? defaultText
        } content: { text in
            Text(text)
        }
    }
}
```

No need for subscriptions, state objects, etc. The content view will be rendered with the most up-to-date result of the function provided, and hides whenever that result is `nil`. You can use this in any app, item view, or view component. It works well for read-only components.

**`ItemStoreBinding`** is similar, but it also lets you provide a setter function, and it gives a two-way binding to your subview.


## Contribute

If you build new providers, apps, item views, or view components that you think others might enjoy, submit a pull request with them included.

Similarly, if you find and fix any bugs or issues, please submit those as well. Your contribution is appreciated!

