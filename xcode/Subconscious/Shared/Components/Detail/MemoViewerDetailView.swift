//
//  MemoViewerDetailView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 3/15/23.
//

import SwiftUI
import Combine
import os
import ObservableStore

/// Display a read-only memo detail view.
/// Used for content from other spheres that we don't have write access to.
struct MemoViewerDetailView: View {
    @StateObject private var store = Store(
        state: MemoViewerDetailModel(),
        environment: AppEnvironment.default
    )

    var description: MemoViewerDetailDescription
    var notify: (MemoViewerDetailNotification) -> Void

    var body: some View {
        VStack {
            switch store.state.loadingState {
            case .loading:
                MemoViewerDetailLoadingView(
                    notify: notify
                )
            case .loaded:
                MemoViewerDetailLoadedView(
                    title: store.state.title,
                    editor: store.state.editor,
                    traversalPath: description.traversalPath,
                    backlinks: store.state.backlinks,
                    send: store.send,
                    notify: notify
                )
            case .notFound:
                MemoViewerDetailNotFoundView(
                    backlinks: store.state.backlinks,
                    notify: notify
                )
            }
        }
        .navigationTitle(store.state.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible)
        .toolbarBackground(Color.background, for: .navigationBar)
        .toolbar(content: {
            DetailToolbarContent(
                address: store.state.address,
                defaultAudience: store.state.defaultAudience,
                onTapOmnibox: {
                    store.send(.presentMetaSheet(true))
                }
            )
        })
        .onAppear {
            store.send(.appear(description))
        }
        .onReceive(store.actions) { action in
            let message = String.loggable(action)
            MemoViewerDetailModel.logger.debug("[action] \(message)")
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.isMetaSheetPresented },
                send: store.send,
                tag: MemoViewerDetailAction.presentMetaSheet
            )
        ) {
            MemoViewerDetailMetaSheetView(
                state: store.state.metaSheet,
                send: Address.forward(
                    send: store.send,
                    tag: MemoViewerDetailMetaSheetCursor.tag
                )
            )
        }
    }
}

/// View for the "not found" state of content
struct MemoViewerDetailNotFoundView: View {
    var backlinks: [EntryStub]
    var notify: (MemoViewerDetailNotification) -> Void
    var contentFrameHeight = UIFont.appTextMono.lineHeight * 8
    
    func onBacklinkSelect(_ link: EntryLink) {
        notify(
            .requestDetail(
                MemoDetailDescription.from(
                    address: link.address,
                    fallback: link.title
                )
            )
        )
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Nothing here yet")
            }
            .frame(minHeight: contentFrameHeight)
            .foregroundColor(.secondary)
            ThickDividerView()
                .padding(.bottom, AppTheme.unit4)
            BacklinksView(
                backlinks: backlinks,
                onSelect: onBacklinkSelect
            )
        }
    }
}

struct MemoViewerDetailLoadingView: View {
    var notify: (MemoViewerDetailNotification) -> Void

    var body: some View {
        ProgressView()
    }
}

struct MemoViewerDetailLoadedView: View {
    var title: String
    var editor: SubtextTextModel
    var traversalPath: TraversalPath
    var backlinks: [EntryStub]
    var send: (MemoViewerDetailAction) -> Void
    var notify: (MemoViewerDetailNotification) -> Void
    
    func onBacklinkSelect(_ link: EntryLink) {
        notify(
            .requestDetail(
                MemoDetailDescription.from(
                    address: link.address,
                    fallback: link.title
                )
            )
        )
    }
    
    private func onLink(
        url: URL
    ) -> Bool {
        guard let sub = url.toSubSlashlinkURL() else {
            return true
        }
        notify(
            .requestFindDetail(
                slashlink: sub.slashlink,
                traversalPath: traversalPath,
                fallback: sub.fallback
            )
        )
        return false
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    SubtextTextViewRepresentable(
                        state: editor,
                        send: Address.forward(
                            send: send,
                            tag: MemoViewerDetailSubtextTextCursor.tag
                        ),
                        frame: geometry.frame(in: .local),
                        onLink: self.onLink
                    )
                    .insets(
                        EdgeInsets(
                            top: AppTheme.padding,
                            leading: AppTheme.padding,
                            bottom: AppTheme.padding,
                            trailing: AppTheme.padding
                        )
                    )
                    .frame(
                        minHeight: UIFont.appTextMono.lineHeight * 8
                    )
                    ThickDividerView()
                        .padding(.bottom, AppTheme.unit4)
                    BacklinksView(
                        backlinks: backlinks,
                        onSelect: onBacklinkSelect
                    )
                }
            }
        }
    }
}

// MARK: Notifications
/// Actions forwarded up to the parent context to notify it of specific
/// lifecycle events that happened within our component.
enum MemoViewerDetailNotification: Hashable {
    case requestDetail(_ description: MemoDetailDescription)
    /// Request detail from any audience scope
    case requestFindDetail(
        slashlink: Slashlink,
        traversalPath: TraversalPath,
        fallback: String
    )
}

/// A description of a memo detail that can be used to set up the memo
/// detal's internal state.
struct MemoViewerDetailDescription: Hashable {
    var address: MemoAddress
    var traversalPath: TraversalPath = .none
}

// MARK: Actions
enum MemoViewerDetailAction: Hashable {
    case editor(SubtextTextAction)
    case metaSheet(MemoViewerDetailMetaSheetAction)
    case appear(_ description: MemoViewerDetailDescription)
    case setDetail(_ detail: MemoDetailResponse?)
    case failLoadDetail(_ message: String)
    case presentMetaSheet(_ isPresented: Bool)
    
    /// Synonym for `.metaSheet(.setAddress(_))`
    static func setMetaSheetAddress(_ address: MemoAddress) -> Self {
        .metaSheet(.setAddress(address))
    }
}

// MARK: Model
struct MemoViewerDetailModel: ModelProtocol {
    typealias Action = MemoViewerDetailAction
    typealias Environment = AppEnvironment
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoViewerDetail"
    )
    
    var loadingState = LoadingState.loading
    
    var address: MemoAddress?
    var defaultAudience = Audience.local
    var title = ""
    var editor = SubtextTextModel(isEditable: false)
    var backlinks: [EntryStub] = []
    
    // Bottom sheet with meta info and actions for this memo
    var isMetaSheetPresented = false
    var metaSheet = MemoViewerDetailMetaSheetModel()
    
    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<Self> {
        switch action {
        case .editor(let action):
            return MemoViewerDetailSubtextTextCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .metaSheet(let action):
            return MemoViewerDetailMetaSheetCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .appear(let description):
            return appear(
                state: state,
                environment: environment,
                description: description
            )
        case .setDetail(let response):
            return setDetail(
                state: state,
                environment: environment,
                response: response
            )
        case .failLoadDetail(let message):
            logger.log("\(message)")
            return Update(state: state)
        case .presentMetaSheet(let isPresented):
            return presentMetaSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        }
    }
    
    static func appear(
        state: Self,
        environment: Environment,
        description: MemoViewerDetailDescription
    ) -> Update<Self> {
        var model = state
        model.loadingState = .loading
        model.address = description.address
        
        let fx: Fx<Action> = environment.data.readMemoDetailPublisher(
            address: description.address
        ).map({ response in
            Action.setDetail(response)
        }).eraseToAnyPublisher()
        return update(
            state: model,
            // Set meta sheet address as well
            action: .setMetaSheetAddress(description.address),
            environment: environment
        ).mergeFx(fx)
    }
    
    static func setDetail(
        state: Self,
        environment: Environment,
        response: MemoDetailResponse?
    ) -> Update<Self> {
        var model = state
        // If no response, then mark not found
        guard let response = response else {
            model.loadingState = .notFound
            return Update(state: model)
        }
        model.loadingState = .loaded
        let memo = response.entry.contents
        model.address = response.entry.address
        model.title = memo.title()
        model.backlinks = response.backlinks
        return update(
            state: model,
            action: .editor(.setText(memo.body)),
            environment: environment
        )
    }
    
    static func presentMetaSheet(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isMetaSheetPresented = isPresented
        return Update(state: model)
    }
}

//  MARK: Cursors
/// Editor cursor
struct MemoViewerDetailSubtextTextCursor: CursorProtocol {
    static func get(state: MemoViewerDetailModel) -> SubtextTextModel {
        state.editor
    }

    static func set(
        state: MemoViewerDetailModel,
        inner: SubtextTextModel
    ) -> MemoViewerDetailModel {
        var model = state
        model.editor = inner
        return model
    }

    static func tag(_ action: SubtextTextAction) -> MemoViewerDetailAction {
        return .editor(action)
    }
}

/// Meta sheet cursor
struct MemoViewerDetailMetaSheetCursor: CursorProtocol {
    typealias Model = MemoViewerDetailModel
    typealias ViewModel = MemoViewerDetailMetaSheetModel

    static func get(state: Model) -> ViewModel {
        state.metaSheet
    }

    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.metaSheet = inner
        return model
    }

    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .requestDismiss:
            return .presentMetaSheet(false)
        default:
            return .metaSheet(action)
        }
    }
}

struct MemoViewerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MemoViewerDetailLoadedView(
            title: "Truth, The Prophet",
            editor: SubtextTextModel(
                text:"""
                Say not, "I have found _the_ truth," but rather, "I have found a truth."

                Say not, "I have found the path of the soul." Say rather, "I have met the soul walking upon my path."

                For the soul walks upon all paths. /infinity-paths

                The soul walks not upon a line, neither does it grow like a reed.

                The soul unfolds itself, like a [[lotus]] of countless petals.
                """
            ),
            traversalPath: .none,
            backlinks: [],
            send: { action in },
            notify: { action in }
        )

        MemoViewerDetailNotFoundView(
            backlinks: [
                EntryStub(
                    address: MemoAddress("public::@bob/bar")!,
                    excerpt: "The hidden well-spring of your soul must needs rise and run murmuring to the sea; And the treasure of your infinite depths would be revealed to your eyes. But let there be no scales to weigh your unknown treasure; And seek not the depths of your knowledge with staff or sounding line. For self is a sea boundless and measureless.",
                    modified: Date.now
                ),
                EntryStub(
                    address: MemoAddress("public::@bob/baz")!,
                    excerpt: "Think you the spirit is a still pool which you can trouble with a staff? Oftentimes in denying yourself pleasure you do but store the desire in the recesses of your being. Who knows but that which seems omitted today, waits for tomorrow?",
                    modified: Date.now
                )
            ],
            notify: { action in }
        )
    }
}
