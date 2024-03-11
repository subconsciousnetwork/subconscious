//
//  TransitionExperimentview.swift
//  Subconscious
//
//  Created by Ben Follington on 4/3/2024.
//

import SwiftUI
import ObservableStore

struct TransitionContentView2: View {
    @Namespace private var namespace
    @State private var selectedItem: EntryStub? = nil
    @State private var showModal = false
    
    @State var items = [
        EntryStub.dummyData(),
        EntryStub.dummyData(),
        EntryStub.dummyData(),
        EntryStub.dummyData(),
        EntryStub.dummyData(),
        EntryStub.dummyData(),
    ]
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    LazyVStack {
                            ForEach(items) { item in
                                Button(
                                    action: {
                                        withAnimation {
                                            selectedItem = item
                                            showModal = true
                                        }
                                    }
                                ) {
                                    EntryRow(
                                        entry: item,
                                        liked: false,
                                        highlight: item.highlightColor,
                                        onLink: { _ in }
                                    )
                                }
                                .buttonStyle(
                                    EntryListRowButtonStyle(
                                        color: item.color
                                    )
                                )
                                .matchedGeometryEffect(id: item.id, in: namespace, anchor: .center, isSource: !showModal)
                                .zIndex(showModal && selectedItem == item ? 999 : 0)
                            }
                            .scaleEffect(x: showModal ? 0.95 : 1, y: showModal ? 0.95 : 1)
                    }
                }
            }
            .overlay(Rectangle()
                .ignoresSafeArea(.all)
                .foregroundStyle(Material.ultraThin.opacity(0.5))
                .opacity(showModal ? 0.75 : 0)
                .allowsHitTesting(false)
            )
            .disabled(showModal)
            .allowsHitTesting(!showModal)

            .offset(y: showModal ? 16 : 0)
            
            
            if let selectedItem = selectedItem, showModal {
//                EditorModalSheetView(app: app, item: selectedItem, namespace: namespace, dismiss: {
//                    showModal = false
//                    })
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .padding(.top, 44)
//                    .ignoresSafeArea(.all)
//                    .cornerRadius(8, corners: .allCorners)
//                    .transition(.push(from: .bottom))
//                    .zIndex(999)
            }
        }
        .animation(DeckTheme.friendlySpring, value: showModal)
    }
}

struct EditorModalSheetView: View {
    @ObservedObject var app: Store<AppModel>
    var item: EntryStub
    var namespace: Namespace.ID
    @State var dragAmount: CGFloat = 0
    let dragThreshold: CGFloat = 64
    var dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: dismiss, label: { Image(systemName: "chevron.left")})
                Spacer()
                
                OmniboxView(
                    address: item.address,
                    defaultAudience: .public,
                    color: item.highlightColor
                )
                
                Spacer()
            }
                .padding(AppTheme.padding)
                .foregroundStyle(item.highlightColor)
                .background(item.color)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragAmount = gesture.translation.height
                        }
                        .onEnded { _ in
                            if dragAmount > dragThreshold {
                              dragAmount = 0
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                                dismiss()
                                }
                            } else {
                                dragAmount = 0
                            }
                        }
                )
                
            MemoEditorDetailView(app: app, description: MemoEditorDetailDescription(address: item.address), notify: { _ in })
        }
        .background(item.color)
        .offset(y: dragAmount)
        .matchedGeometryEffect(id: item.id, in: namespace, isSource: false)
        .animation(.interactiveSpring(), value: dragAmount)
        .onDisappear {
            dragAmount = 0
        }
    }
}


struct TransitionContentView2_Previews: PreviewProvider {
    static var previews: some View {
        TransitionContentView2()
    }
}

