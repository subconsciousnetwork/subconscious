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
    case postPublicly
    case dismiss
    case setPresented(Bool)
    case metaSheetPresented(_ presented: Bool)
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
    var metaSheetPresented = false
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
        case let .metaSheetPresented(presented):
            var model = state
            model.metaSheetPresented = presented
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
            ).animation(.easeOutCubic(duration: 0.3))
        case .postPublicly:
            return update(state: state, actions: [
                .dismiss
            ], environment: environment)
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
                .frame(height: 44)
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
                                dragAmount = 1024
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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
                        .background(editor.state.background)
                        .frame(maxHeight: .infinity)
                        .disabled(!store.state.presented)
                        .allowsHitTesting(store.state.presented)
                    }
                    
                    VStack {
                        Spacer()
                            .allowsHitTesting(false)
                        
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .foregroundStyle(editor.state.background)
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
                                        .frame(maxWidth: 192, alignment: .leading)
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
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .offset(y: dragAmount)
            .matchedGeometryEffect(id: item.id, in: namespace, isSource: false)
            .animation(.interactiveSpring(), value: dragAmount)
            .task {
                store.send(.setPresented(true))
            }
            .sheet(
                isPresented: store.binding(
                    get: \.metaSheetPresented,
                    tag: EditorModalSheetAction.metaSheetPresented
                )
            ) {
                VStack {
                    Picker(
                        "Audience",
                        selection: editor.binding(
                            get: \.audience,
                            tag: MemoEditorDetailAction.requestUpdateAudience
                        )
                    ) {
                        ForEach(Audience.allCases, id: \.self) {
                            Text("\($0)".capitalized)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack(spacing: AppTheme.padding) {
                        let themeColors = ThemeColor.allCases
                        
                        ForEach(themeColors, id: \.self) { themeColor in
                            Button(
                                action: {
                                    editor.send(.requestAssignNoteColor(themeColor))
                                }
                            ) {
                                ZStack {
                                    Circle()
                                        .fill(themeColor.toColor())
                                    Circle()
                                        .stroke(Color.separator)
                                    if themeColor == editor.state.themeColor {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 32, height: 32)
                            }
                        }
                    }
                    
                    MetaTableView {
                        Button(
                            action: {
                                store.send(.metaSheetPresented(false))
                                
                                Task {
                                    try? await Task.sleep(for: .seconds(0.01))
                                    editor.send(.presentMetaSheet(true))
                                    try? await Task.sleep(for: .seconds(0.01))
                                    editor.send(.metaSheet(.presentRenameSheetFor(editor.state.address)))
                                }
                            }
                        ) {
                            Label(
                                "Edit link",
                                systemImage: "link"
                            )
                        }
                        .buttonStyle(RowButtonStyle())
                        
//                        Divider()
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.padding)
                .presentationDetents([.height(256)])
            }
        }
    }
}

