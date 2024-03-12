//
//  TransitionExperimentview.swift
//  Subconscious
//
//  Created by Ben Follington on 4/3/2024.
//

import SwiftUI
import ObservableStore
import os

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

enum EditorModalSheetAction: Equatable, Hashable {
    case requestUpdateAudience(Audience)
    case requestAssignNoteColor(ThemeColor)
    case colorSheetPresented(_ presented: Bool)
    case editLinkSheetPresented(_ presented: Bool)
}

struct EditorModalSheetModel: ModelProtocol, Equatable {
    typealias Action = EditorModalSheetAction
    typealias Environment = AppEnvironment
    
    var item: EntryStub = EntryStub.dummyData()
    var audience: Audience = .local
    var themeColor: ThemeColor = ThemeColor.a
    var colorSheetIsPresented = false
    var editLinkSheetIsPresented = false
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case let .requestUpdateAudience(audience):
            var model = state
            model.audience = audience
            return Update(state: model)
        case let .requestAssignNoteColor(color):
            var model = state
            model.themeColor = color
            return Update(state: model)
        case let .colorSheetPresented(presented):
            var model = state
            model.colorSheetIsPresented = presented
            return Update(state: model)
        case let .editLinkSheetPresented(presented):
            var model = state
            model.editLinkSheetIsPresented = presented
            return Update(state: model)
        }
    }
}

struct RedMenu: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .foregroundColor(.red)
    }
}

struct EditorModalSheetView: View {
    @ObservedObject var app: Store<AppModel>
    var store: ViewStore<EditorModalSheetModel> {
        app.viewStore(
            get: \.editorSheet,
            tag: AppAction.editorSheet
        )
    }
    
    var item: EntryStub
    var namespace: Namespace.ID
    @State var dragAmount: CGFloat = 0
    let dragThreshold: CGFloat = 64
    var dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    
                    Spacer(minLength: 0)
                    Button(
                        action: dismiss,
                        label: {
                            Text(
                                "Close"
                            ).bold()
                        }
                    )
                }
                
                AudienceMenuButtonView(
                    audience: store.binding(
                        get: \.audience,
                        tag: EditorModalSheetAction.requestUpdateAudience
                    )
                )
                .tint(item.highlightColor)
            }
                .padding(AppTheme.padding)
                .foregroundStyle(item.highlightColor)
                .tint(item.highlightColor)
                .background(item.color)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragAmount = gesture.translation.height
                        }
                        .onEnded { _ in
                            if dragAmount > dragThreshold {
                              dragAmount = 0
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                dismiss()
                                }
                            } else {
                                dragAmount = 0
                            }
                        }
                )
                
            ZStack {
                // Heinous workaround for a bug with keyboard toolbars
                // https://stackoverflow.com/questions/71206502/keyboard-toolbar-buttons-not-showing
                NavigationStack {
                    MemoEditorDetailView(
                        app: app,
                        description: MemoEditorDetailDescription(
                            address: item.address
                        ),
                        notify: { _ in }
                    )
                    .padding(0)
                    .background(item.color)
                }

                VStack {
                    Spacer()
                        .allowsHitTesting(false)
                    
                    HStack(spacing: 0) {
                        Button(
                            action: {
                                dismiss()
                            },
                            label: {
                                HStack(spacing: AppTheme.unit2) {
                                    Image(systemName: "link")
                                        .fontWeight(.medium)
                                        .font(.caption)
                                    
                                    Text("\(item.address.markup)")
                                        .lineLimit(1)
                                        .fontWeight(.medium)
                                        .font(.caption)
                                        .foregroundStyle(item.highlightColor)
                                }
                                .frame(maxWidth: 192, alignment: .leading)
                            }
                        )
                        
                        Spacer()
                        
                        Button(
                            action: {
                                store.send(
                                    .colorSheetPresented(
                                        true
                                    )
                                )
                            },
                            label: {
                                Image(
                                    systemName: "paintpalette"
                                )
                            }
                        )
                    }
                    .foregroundColor(item.highlightColor)
                }
                .padding(
                    EdgeInsets(
                        top: DeckTheme.cardPadding,
                        leading: DeckTheme.cardPadding,
                        bottom: 2 * DeckTheme.cardPadding,
                        trailing: DeckTheme.cardPadding
                    )
                )
            }
        }
        .background(item.color)
        .offset(y: dragAmount)
        .matchedGeometryEffect(id: item.id, in: namespace, isSource: false)
        .animation(.interactiveSpring(), value: dragAmount)
        .onDisappear {
            dragAmount = 0
        }
        .sheet(
            isPresented: store.binding(
                get: \.colorSheetIsPresented,
                tag: EditorModalSheetAction.colorSheetPresented
            )
        ) {
            HStack(spacing: AppTheme.padding) {
                let themeColors = ThemeColor.allCases
                
                ForEach(themeColors, id: \.self) { themeColor in
                    Button(
                        action: {
                            store.send(.requestAssignNoteColor(themeColor))
                        }
                    ) {
                        ZStack {
                            Circle()
                                .fill(themeColor.toColor())
                            Circle()
                                .stroke(Color.separator)
                            if themeColor == store.state.themeColor {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 32, height: 32)
                    }
                }
            }
            .presentationDetents([.height(256)])
        }
        .sheet(
            isPresented: store.binding(
                get: \.editLinkSheetIsPresented,
                tag: EditorModalSheetAction.editLinkSheetPresented
            )
        ) {
            HStack(spacing: AppTheme.padding) {
                Text("todo")
            }
            .presentationDetents([.height(256)])
        }
    }
}


struct TransitionContentView2_Previews: PreviewProvider {
    static var previews: some View {
        TransitionContentView2()
    }
}

