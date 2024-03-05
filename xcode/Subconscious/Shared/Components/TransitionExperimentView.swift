//
//  TransitionExperimentview.swift
//  Subconscious
//
//  Created by Ben Follington on 4/3/2024.
//

import SwiftUI

struct Item: Identifiable {
    var id = UUID()
    var title: String
    var color: Color
    
    init(title: String) {
        self.title = title
        self.id = UUID()
        self.color = ThemeColor.allCases.map { c in c.toColor() }.randomElement()!
    }
}

struct TestCardView: View {
    var item: Item
    
    var body: some View {
        VStack {
            Text(item.title)
        }
        .padding(AppTheme.padding)
        .frame(maxWidth: .infinity)
        .background(item.color)
        .cornerRadius(8, corners: .allCorners)
    }
}

struct TestCardEditView: View {
    var item: Item
    @State var text: String
    var autofocus = true
    @FocusState var focusState: Bool
    
    var body: some View {
        VStack {
            TextField(text: $text, label: { })
                .id("editor")
                .focused($focusState)
        }
        .frame(maxWidth: .infinity)
        .background(item.color)
        .onAppear {
            if autofocus {
                focusState.toggle()
            }
        }
        .onDisappear {
            focusState = false
        }
    }
}

struct TransitionContentView: View {
    @Namespace private var namespace
    @State private var selectedItem: Item? = nil
    @State private var showModal = false
    
    @State var items = [
        Item(title: "Item 1"),
        Item(title: "Item 2"),
        Item(title: "Item 3"),
        Item(title: "Item 4"),
        Item(title: "Item 5"),
        Item(title: "Item 6"),
    ]
    
    var body: some View {
        ZStack {
            VStack {
                ForEach(items) { item in
                    TestCardView(item: item)
                        .matchedGeometryEffect(id: item.id, in: namespace)
                        .onTapGesture {
                            withAnimation {
                                selectedItem = item
                                showModal = true
                            }
                        }
                }
            }
            .opacity(showModal ? 0.5 : 1)
            .scaleEffect(showModal ? 0.95 : 1)
            .disabled(showModal)
            
            if showModal, let selectedItem = selectedItem {
                CustomModalView(item: selectedItem, showModal: $showModal, namespace: namespace)
            }
        }
        .animation(.easeOutCubic(), value: showModal)
    }
}

struct CustomModalView: View {
    var item: Item
    @Binding var showModal: Bool
    var namespace: Namespace.ID
    @State var maximize: Bool = false
    
    // The Boolean value to toggle
    @State private var isToggled: Bool = false
    
    // The threshold for toggling
    @State var dragAmount: CGFloat = 0
    let dragThreshold: CGFloat = 64

    var body: some View {
        VStack {
            if !maximize {
                Spacer()
            }
            
            VStack {
                ScrollView {
                    TestCardEditView(item: item, text: item.title)
                }
            }
            .toolbarBackground(item.color, for: .navigationBar)
            .padding(DeckTheme.cardPadding)
            .frame(minHeight: 128, maxHeight: maximize ? .infinity : 256, alignment: .top)
            .background(item.color)
            .cornerRadius(maximize ? 0 : 32, corners: [.topLeft, .topRight])
            .matchedGeometryEffect(id: item.id, in: namespace)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        withAnimation(.interactiveSpring()) {
                            dragAmount = gesture.translation.height
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.interactiveSpring()) {
                        // Check if the drag distance exceeds the threshold
                        if dragAmount < -dragThreshold {
                            // Toggle the Boolean value
                            maximize = true
                        }
                        
                        if dragAmount > 2 * dragThreshold {
                            if !maximize {
                                showModal = false
                            }
                        }
                        
                        if dragAmount > dragThreshold {
                            if maximize {
                                // Toggle the Boolean value
                                maximize = false
                            }
                        }
                        
                            dragAmount = 0
                        }
                    }
            )
            .offset(y: dragAmount)
            .transition(.scale)
            .shadow(
                color: DeckTheme.cardShadow.opacity(
                    maximize ? 0 : 0.25
                ),
                radius: 2.5,
                x: 0,
                y: 1.5
            )
        }
        .frame(maxHeight: .infinity)
        .background(maximize ? item.color : .primary.opacity(0.1))
        .onTapGesture {
            showModal = false
        }
        .animation(.interactiveSpring(), value: showModal)
        .animation(.interactiveSpring(), value: maximize)
        .animation(.easeOutCubic(), value: dragAmount)
        
    }
}

struct TransitionContentView_Previews: PreviewProvider {
    static var previews: some View {
        TransitionContentView()
    }
}

