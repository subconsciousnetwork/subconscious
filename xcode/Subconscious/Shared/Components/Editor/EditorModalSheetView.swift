//
//  EditorModalSheetView.swift
//  Subconscious
//
//  Created by Ben Follington on 4/3/2024.
//

import SwiftUI
import ObservableStore
import os

enum EditorModalSheetAction: Equatable, Hashable {
    case editEntry(EntryStub)
    case postPublicly
    case dismiss
    case setPresented(Bool)
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
    var presented = false
    
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
        case let .editEntry(entry):
            var model = state
            model.item = entry
            model.presented = true
            environment.selectionFeedback.prepare()
            environment.selectionFeedback.selectionChanged()
            return Update(state: model).animation(DeckTheme.friendlySpring)
        case .dismiss:
            var model = state
            model.item = nil
            environment.selectionFeedback.prepare()
            environment.selectionFeedback.selectionChanged()
            return update(
                state: model,
                action: .setPresented(
                    false
                ),
                environment: environment
            ).animation(.easeOutCubic(duration: 0.3))
        case .postPublicly:
            return update(state: state, actions: [
                .dismiss
            ], environment: environment)
        }
    }
}

struct EditorModalSheetView: View {
    @ObservedObject var app: Store<AppModel>
    private static let modalMemoEditorDetailStoreLogger = Logger(
        subsystem: Config.default.rdns,
        category: "ModalMemoEditorDetailStore"
    )
    var store: ViewStore<EditorModalSheetModel> {
        app.viewStore(
            get: \.editorSheet,
            tag: AppAction.editorSheet
        )
    }
    
    /// Once we are ready to migrate to the modal sheet version of the editor we can simplify this model
    @StateObject private var editor = Store(
        state: MemoEditorDetailModel(),
        action: .start,
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: modalMemoEditorDetailStoreLogger
    )
    
    var namespace: Namespace.ID
    @State var dragAmount: CGFloat = 0
    private static let dragThreshold: CGFloat = 64
    private static let discardThrowDistance: CGFloat = 1024
    private static let discardThrowDelay: CGFloat = 0.15

    func onDismiss() {
        store.send(.dismiss)
    }
    
    func onPost() {
        editor.send(.requestUpdateAudience(.public))
        store.send(.postPublicly)
    }
    
    var body: some View {
        if let item = store.state.item {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button(
                        action: onDismiss,
                        label: { Image(systemName: "multiply").bold() }
                    )
                    
                    Spacer()
                    
                    if editor.state.audience == .local {
                        Button(
                            action: onPost,
                            label: { Text(String(localized: "Post")).bold() }
                        )
                    } else if editor.state.saveState == .unsaved {
                        Button(
                            action: onDismiss,
                            label: { Text(String(localized: "Save")).bold() }
                        )
                    }
                }
                .padding(AppTheme.padding)
                .frame(height: AppTheme.minTouchSize)
                .foregroundStyle(editor.state.highlight)
                .tint(editor.state.highlight)
                .background(editor.state.background)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragAmount = gesture.translation.height
                        }
                        .onEnded { _ in
                            if dragAmount > Self.dragThreshold {
                                dragAmount = Self.discardThrowDistance
                                DispatchQueue.main.asyncAfter(deadline: .now() + Self.discardThrowDelay) {
                                    onDismiss()
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
                        EditorModalSheetDetailView(
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
                        .background(editor.state.background)
                        .frame(maxHeight: .infinity)
                        .disabled(!store.state.presented)
                        .allowsHitTesting(store.state.presented)
                    }
                    
                    VStack {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        ZStack(alignment: .bottom) {
                            // Gradient background for the bottom toolbar
                            Rectangle()
                                .foregroundStyle(editor.state.background)
                                .frame(maxHeight: AppTheme.minGradientMaskSize)
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(
                                            colors: [.clear, .black, .black]
                                        ),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            HStack(spacing: 0) {
                                Button(
                                    action: {
                                        editor.send(.presentMetaSheet(true))
                                    },
                                    label: {
                                        HStack(spacing: AppTheme.unit2) {
                                            Image(audience: editor.state.audience)
                                                .fontWeight(.medium)
                                                .font(.caption)
                                            
                                            Text("\(editor.state.address?.markup ?? "-")")
                                                .lineLimit(1)
                                                .fontWeight(.medium)
                                                .font(.caption)
                                        }
                                        .frame(alignment: .leading)
                                    }
                                )
                                
                                Spacer()
                                
                                Button(
                                    action: {
                                        editor.send(.presentMetaSheet(true))
                                    },
                                    label: {
                                        Image(
                                            systemName: "ellipsis"
                                        )
                                    }
                                )
                            }
                            .foregroundColor(editor.state.highlight)
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
            .background(editor.state.background)
            .cornerRadius(AppTheme.cornerRadiusLg, corners: [.topLeft, .topRight])
            .offset(y: dragAmount)
            .matchedGeometryEffect(id: item.id, in: namespace, isSource: false)
            .animation(.interactiveSpring(), value: dragAmount)
        }
    }
}

