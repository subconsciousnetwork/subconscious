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
                    dom: store.state.dom,
                    address: description.address,
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
    var dom: Subtext
    var address: MemoAddress
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
    ) -> OpenURLAction.Result {
        guard let link = url.toSubSlashlinkURL() else {
            return .systemAction
        }
        
        notify(
            .requestFindDetail(
                address: address,
                link: link
            )
        )
        return .handled
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    VStack {
                        SubtextView(
                            subtext: dom
                        ).textSelection(
                            .enabled
                        ).environment(\.openURL, OpenURLAction { url in
                            self.onLink(url: url)
                        })
                        Spacer()
                    }
                    .padding()
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
        address: MemoAddress,
        link: SubSlashlinkLink
    )
}

/// A description of a memo detail that can be used to set up the memo
/// detal's internal state.
struct MemoViewerDetailDescription: Hashable {
    var address: MemoAddress
}

// MARK: Actions
enum MemoViewerDetailAction: Hashable {
    case metaSheet(MemoViewerDetailMetaSheetAction)
    case appear(_ description: MemoViewerDetailDescription)
    case setDetail(_ detail: MemoDetailResponse?)
    case setDom(Subtext)
    case failLoadDetail(_ message: String)
    case presentMetaSheet(_ isPresented: Bool)
    
    /// Synonym for `.metaSheet(.setAddress(_))`
    static func setMetaSheetAddress(_ address: MemoAddress) -> Self {
        .metaSheet(.setAddress(address))
    }
}

extension MemoViewerDetailAction: CustomLogStringConvertible {
    var logDescription: String {
        switch self {
        case .setDetail:
            return "setDetail(...)"
        default:
            return String(describing: self)
        }
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
    var dom: Subtext = Subtext.empty
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
        case .setDom(let dom):
            return setDom(
                state: state,
                environment: environment,
                dom: dom
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
        
        let dom = memo.dom()
        
        return update(
            state: model,
            action: .setDom(dom),
            environment: environment
        )
    }
    
    static func setDom(
        state: Self,
        environment: Environment,
        dom: Subtext
    ) -> Update<Self> {
        var model = state
        model.dom = dom
        return Update(state: model)
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
            dom: Subtext(
                markup:"""
                Say not, "I have found _the_ truth," but rather, "I have found a truth."

                Say not, "I have found the path of the soul." Say rather, "I have met the soul walking upon my path."

                For the soul walks upon all paths. /infinity-paths

                The soul walks not upon a line, neither does it grow like a reed.

                The soul unfolds itself, like a [[lotus]] of countless petals.
                """
            ),
            address: MemoAddress.local(Slug("truth-the-prophet")!),
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
