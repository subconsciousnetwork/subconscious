//
//  TransitionExperimentview.swift
//  Subconscious
//
//  Created by Ben Follington on 4/3/2024.
//

import SwiftUI

struct TransitionContentView2: View {
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
            .fullScreenCover(isPresented: $showModal, content: {
                if let selectedItem = selectedItem {
                    CustomModalView2(item: selectedItem, showModal: $showModal, namespace: namespace)
                }
            })
        }
        .animation(.easeOutCubic(), value: showModal)
    }
}

struct CustomModalView2: View {
    var item: Item
    @Binding var showModal: Bool
    var namespace: Namespace.ID

    var body: some View {
        VStack {
            ScrollView {
                TestCardEditView(item: item, text: item.title, autofocus: true)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .matchedGeometryEffect(id: item.id, in: namespace)
                //            .transition(.push(from: .bottom))
            }
            .padding(DeckTheme.cardPadding)
            .background(item.color)
        }
        .background(.primary.opacity(0.1))
        .animation(.easeOutCubic(), value: showModal)
        .presentationDetents([.large])
    }
}


struct TransitionContentView2_Previews: PreviewProvider {
    static var previews: some View {
        TransitionContentView2()
    }
}

