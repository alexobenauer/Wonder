//
//  ItemStoreSubscriber.swift
//  ItemizedPlayground
//
//  Created by Alexander Obenauer on 11/7/23.
//

import SwiftUI

protocol ItemStoreSubscriber {
    func newFacts(_ facts: [Fact])
}

extension ItemStore {
    func subscribeToNewFacts(_ subscriber: ItemStoreSubscriber) -> (() -> Void) {
        notifier.subscribe(subscriber)
    }
    
    class SubscriberNotifier {
        private var subscribers: [String: ItemStoreSubscriber] = [:]
        private let debouncer = Debouncer(delay: 0.1)
        private var newFacts: [Fact] = []
        
        func subscribe(_ subscriber: ItemStoreSubscriber) -> (() -> Void) {
            let id = UUID().uuidString
            
            self.subscribers[id] = subscriber
            
            return {
                self.subscribers.removeValue(forKey: id)
            }
        }
        
        func notifySubscribers(newFacts: [Fact]) {
            self.newFacts.append(contentsOf: newFacts)
            
            debouncer.debounce {
                self.newFacts.sort(by: { $0.timestamp > $1.timestamp })
                
                self.subscribers.values.forEach {
                    $0.newFacts(self.newFacts)
                }
                
                self.newFacts.removeAll()
            }
        }
    }
}


struct ItemStoreValue<Content: View, ValueType>: View {
    init(getValue: @escaping () -> ValueType?, content: @escaping (ValueType) -> Content, defaultContent: (() -> Content)? = nil) {
        self._subscriber = StateObject(wrappedValue: SimpleItemStoreSubscriber(getValue: getValue))
        self.content = content
        self.defaultContent = defaultContent
    }
    
    @StateObject private var subscriber: SimpleItemStoreSubscriber<ValueType?>
    
    let content: (ValueType) -> Content
    let defaultContent: (() -> Content)?
    
    @ViewBuilder
    var body: some View {
        if let value = subscriber.value {
            content(value)
        }
        else if let defaultContent {
            defaultContent()
        }
    }
}

struct ItemStoreBinding<Content: View, ValueType: Equatable>: View {
    let content: (Binding<ValueType>) -> Content
    let setValue: (ValueType) -> Void
    
    @State private var value: ValueType
    @ObservedObject private var subscriber: SimpleItemStoreSubscriber<ValueType>
    
    init(
        getValue: @escaping () -> ValueType,
        setValue: @escaping (ValueType) -> Void,
        @ViewBuilder content: @escaping (Binding<ValueType>) -> Content
    ) {
        self._value = State(initialValue: getValue())
        self.setValue = setValue
        self.content = content
        self._subscriber = ObservedObject(wrappedValue: SimpleItemStoreSubscriber(getValue: getValue))
    }
    
    var body: some View {
        return content($value)
            .onChange(of: value) {
                if value != subscriber.value {
                    setValue(value)
                }
            }
            .onChange(of: subscriber.value) {
                if subscriber.value != value {
                    self.value = subscriber.value
                }
            }
    }
}


class SimpleItemStoreSubscriber<ValueType>: ItemStoreSubscriber, ObservableObject {
    init(initialValue: ValueType) {
        self.value = initialValue
    }
    
    init(getValue: @escaping () -> ValueType) {
        self.value = getValue()
        self.getValue = getValue
        self.unsubscribe = ItemStore.shared.subscribeToNewFacts(self)
    }
    
    func initialize(getUpdatedValue: @escaping () -> ValueType) {
        self.value = getUpdatedValue()
        self.getValue = getUpdatedValue
        self.unsubscribe = ItemStore.shared.subscribeToNewFacts(self)
    }
    
    deinit {
        unsubscribe?()
    }
    
    @Published var value: ValueType
    
    var unsubscribe: (() -> Void)? = nil
    
    var getValue: (() -> ValueType)? = nil
    
    func newFacts(_ facts: [Fact]) {
        self.value = self.getValue?() ?? self.value
    }
}

class GenericItemStoreSubscriber<ValueType>: ItemStoreSubscriber, ObservableObject {
    init(initialValue: ValueType, transformer: @escaping (_ newFacts: [Fact]) -> ValueType) {
        self.value = initialValue
        self.transformer = transformer
        self.unsubscribe = ItemStore.shared.subscribeToNewFacts(self)
    }
    
    init(getInitialValue: () -> ValueType, transformer: @escaping (_ newFacts: [Fact]) -> ValueType) {
        self.value = getInitialValue()
        self.transformer = transformer
        self.unsubscribe = ItemStore.shared.subscribeToNewFacts(self)
    }
    
    deinit {
#if DEBUG
        unsubscribe!()
#else
        unsubscribe?()
#endif
    }
    
    @Published var value: ValueType
    
    var unsubscribe: (() -> Void)? = nil
    
    var transformer: (_ newFacts: [Fact]) -> ValueType
    
    func newFacts(_ facts: [Fact]) {
        self.value = self.transformer(facts)
    }
}

class SignalItemStoreSubscriber: ItemStoreSubscriber {
    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        self.unsubscribe = ItemStore.shared.subscribeToNewFacts(self)
    }
    
    deinit {
#if DEBUG
        unsubscribe!()
#else
        unsubscribe?()
#endif
    }
    
    let onChange: () -> Void
    var unsubscribe: (() -> Void)? = nil
    
    func newFacts(_ facts: [Fact]) {
        onChange()
    }
}
