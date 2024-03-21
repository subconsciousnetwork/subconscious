//
//  TransitionExperimentview.swift
//  Subconscious
//
//  Created by Ben Follington on 4/3/2024.
//

import SwiftUI
import ObservableStore
import os

enum EditorModalSheetAction: Equatable, Hashable {
    case editEntry(EntryStub)
    case dismiss
    case setPresented(Bool)
    case requestUpdateAudience(Audience)
    case requestAssignNoteColor(ThemeColor)
    case colorSheetPresented(_ presented: Bool)
    case editLinkSheetPresented(_ presented: Bool)
}

extension AppAction {
    static func from(_ notification: MemoEditorDetailNotification) -> Self? {
        switch notification {
        case let .requestSaveEntry(entry):
            return .saveEntry(entry)
        case let .requestDelete(address):
            return .deleteEntry(address)
        case let .requestMoveEntry(from, to):
            return .moveEntry(from: from, to: to)
        case let .requestMergeEntry(parent, child):
            return .mergeEntry(parent: parent, child: child)
        case let .requestUpdateAudience(address, audience):
            return .updateAudience(address: address, audience: audience)
        case let .requestAssignNoteColor(address, color):
            return .assignColor(address: address, color: color)
        default:
            return nil
        }
    }
}

struct EditorModalSheetModel: ModelProtocol, Equatable {
    typealias Action = EditorModalSheetAction
    typealias Environment = AppEnvironment
    
    var item: EntryStub? = nil
    var audience: Audience = .local
    var themeColor: ThemeColor = ThemeColor.a
    var colorSheetIsPresented = false
    var editLinkSheetIsPresented = false
    var presented = false
    
    var selectionFeedback = UISelectionFeedbackGenerator()
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case let .setPresented(presented):
            var model = state
            model.presented = presented
            return Update(state: model).animation(.easeOutCubic())
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
        case let .editEntry(entry):
            var model = state
            model.item = entry
            model.presented = false
            model.selectionFeedback.prepare()
            model.selectionFeedback.selectionChanged()
            return Update(state: model).animation(DeckTheme.friendlySpring)
        case .dismiss:
            var model = state
            model.item = nil
            model.selectionFeedback.prepare()
            model.selectionFeedback.selectionChanged()
            return update(
                state: model,
                action: .setPresented(
                    false
                ),
                environment: environment
            ).animation(.easeOutCubic())
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
    private static let modalMemoEditorDetailStoreLogger = Logger(
        subsystem: Config.default.rdns,
        category: "ModalMemoEditorDetailStore"
    )
    
    /// Detail keeps a separate internal store for editor state that does not
    /// need to be surfaced in higher level views.
    ///
    /// This gives us a pretty big efficiency win, since keystrokes will only
    /// rerender this view, and not whole app view tree.
    @StateObject private var editor = Store(
        state: MemoEditorDetailModel(),
        action: .start,
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: modalMemoEditorDetailStoreLogger
    )
    
    var store: ViewStore<EditorModalSheetModel> {
        app.viewStore(
            get: \.editorSheet,
            tag: AppAction.editorSheet
        )
    }
    
    var namespace: Namespace.ID
    @State var dragAmount: CGFloat = 0
    private static let dragThreshold: CGFloat = 64
    
    func onDismiss() {
        store.send(.dismiss)
    }
    
    var body: some View {
        if let item = store.state.item {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button(
                        action: onDismiss,
                        label: {
                            Image(systemName: "multiply")
                                .bold()
                        }
                    )
                    Spacer(minLength: 0)
                    Button(
                        action: onDismiss,
                        label: {
                            Text(
                                "Post"
                            ).bold()
                        }
                    )
                }
                .padding(AppTheme.tightPadding)
                .foregroundStyle(item.highlightColor)
                .tint(item.highlightColor)
                .background(item.color)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragAmount = gesture.translation.height
                        }
                        .onEnded { _ in
                            if dragAmount > Self.dragThreshold {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onDismiss()
                                    dragAmount = 0
                                }
                            } else {
                                dragAmount = 0
                            }
                        }
                )
                
                ZStack {
                    // Heinous workaround for a bug with keyboard toolbars in ZStacks
                    // https://stackoverflow.com/questions/71206502/keyboard-toolbar-buttons-not-showing
                    NavigationStack {
                        ModalMemoEditorDetailView(
                            app: app,
                            store: editor,
                            description: MemoEditorDetailDescription(
                                address: item.address
                            ),
                            notify: { notification in
                                guard let action = AppAction.from(notification) else {
                                    return
                                }
                                
                                app.send(action)
                            }
                        )
                        .padding(0)
                        .background(item.color)
                        .frame(maxHeight: .infinity)
                        .disabled(!store.state.presented)
                        .allowsHitTesting(store.state.presented)
                    }
                    
                    VStack {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .foregroundStyle(item.color)
                                .frame(maxHeight: 56*2)
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(
                                            colors: [
                                                .clear,
                                                .black,
                                                .black,
                                            ]
                                        ),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            HStack(spacing: 0) {
                                Button(
                                    action: {
                                        store.send(.colorSheetPresented(true))
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
                                        store.send(.colorSheetPresented(true))
                                    },
                                    label: {
                                        Image(
                                            systemName: "ellipsis"
                                        )
                                    }
                                )
                            }
                            .foregroundColor(item.highlightColor)
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
                }
            }
            .background(item.color)
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .offset(y: dragAmount)
            .matchedGeometryEffect(id: item.id, in: namespace, anchor: .center, isSource: false)
            .animation(.interactiveSpring(), value: dragAmount)
            .onDisappear {
                dragAmount = 0
            }
            .task {
                store.send(.setPresented(false))
                try? await Task.sleep(for: .seconds(0.1))
                store.send(.setPresented(true))
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
}

