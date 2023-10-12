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
    @ObservedObject var app: Store<AppModel>
    
    @StateObject private var store = Store(
        state: MemoViewerDetailModel(),
        environment: AppEnvironment.default
    )
    
    var metaSheet: ViewStore<MemoViewerDetailMetaSheetModel> {
        store.viewStore(
            get: MemoViewerDetailMetaSheetCursor.get,
            tag: MemoViewerDetailMetaSheetCursor.tag
        )
    }

    var description: MemoViewerDetailDescription
    var notify: (MemoViewerDetailNotification) -> Void
    var navigationTitle: String {
        store.state.address?.markup ?? store.state.title
    }

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
                    user: store.state.owner,
                    dom: store.state.dom,
                    transcludePreviews: store.state.transcludePreviews,
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
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible)
        .toolbarBackground(Color.background, for: .navigationBar)
        .toolbar(content: {
            DetailToolbarContent(
                address: store.state.address,
                defaultAudience: store.state.defaultAudience,
                onTapOmnibox: {
                    store.send(.presentMetaSheet(true))
                },
                status: store.state.loadingState
            )
        })
        .onAppear {
            store.send(.appear(description))
        }
        .onReceive(store.actions) { action in
            MemoViewerDetailAction.logger.debug(
                "\(String(describing: action))"
            )
        }
        .onReceive(
            store.actions.compactMap(MemoViewerDetailNotification.from),
            perform: notify
        )
        .onReceive(
            app.actions.compactMap(MemoViewerDetailAction.fromAppAction),
            perform: store.send
        )
        .sheet(
            isPresented: Binding(
                get: { store.state.isMetaSheetPresented },
                send: store.send,
                tag: MemoViewerDetailAction.presentMetaSheet
            )
        ) {
            MemoViewerDetailMetaSheetView(store: metaSheet)
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
            NotFoundView()
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
    var user: UserProfile?
    var dom: Subtext
    var transcludePreviews: [Slashlink: EntryStub]
    var address: Slashlink
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
            .requestFindLinkDetail(
                address: address,
                link: link
            )
        )
        return .handled
    }
    
    private func onViewTransclude(
        address: Slashlink
    ) {
        notify(
            .requestDetail(
                MemoDetailDescription.from(
                    address: address,
                    fallback: address.description
                )
            )
        )
    }
    

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    VStack {
                        SubtextView(
                            subtext: dom,
                            transcludePreviews: transcludePreviews,
                            onViewTransclude: self.onViewTransclude
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
    case requestFindLinkDetail(
        address: Slashlink,
        link: SubSlashlinkLink
    )
    case requestUserProfileDetail(_ address: Slashlink)
}

extension MemoViewerDetailNotification {
    static func from(_ action: MemoViewerDetailAction) -> Self? {
        switch action {
        case let .requestAuthorDetail(user):
            return .requestUserProfileDetail(user.address)
        default:
            return nil
        }
    }
}

/// A description of a memo detail that can be used to set up the memo
/// detal's internal state.
struct MemoViewerDetailDescription: Hashable {
    var address: Slashlink
}

// MARK: Actions
enum MemoViewerDetailAction: Hashable {
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoViewerDetailAction"
    )

    case metaSheet(MemoViewerDetailMetaSheetAction)
    case appear(_ description: MemoViewerDetailDescription)
    case setDetail(_ entry: MemoEntry?)
    case setDom(Subtext)
    case failLoadDetail(_ message: String)
    case presentMetaSheet(_ isPresented: Bool)
    
    case refreshBacklinks
    case succeedRefreshBacklinks(_ backlinks: [EntryStub])
    case failRefreshBacklinks(_ error: String)
    
    case fetchTranscludePreviews
    case succeedFetchTranscludePreviews([Slashlink: EntryStub])
    case failFetchTranscludePreviews(_ error: String)
    
    case fetchOwnerProfile
    case succeedFetchOwnerProfile(UserProfile)
    case failFetchOwnerProfile(_ error: String)
    
    case succeedIndexBackgroundSphere
    case requestAuthorDetail(_ author: UserProfile)
    
    /// Synonym for `.metaSheet(.setAddress(_))`
    static func setMetaSheetAddress(_ address: Slashlink) -> Self {
        .metaSheet(.setAddress(address))
    }
    static func setMetaSheetAuthor(_ author: UserProfile) -> Self {
        .metaSheet(.setAuthor(author))
    }
}

/// React to actions from the root app store
extension MemoViewerDetailAction {
    static func fromAppAction(
        _ action: AppAction
    ) -> MemoViewerDetailAction? {
        switch (action) {
        case .succeedIndexOurSphere(_),
             .succeedIndexPeer(_):
            return .succeedIndexBackgroundSphere
        case _:
            return nil
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
    
    var owner: UserProfile?
    var address: Slashlink?
    var defaultAudience = Audience.local
    var title = ""
    var dom: Subtext = Subtext.empty
    var backlinks: [EntryStub] = []
    
    // Bottom sheet with meta info and actions for this memo
    var isMetaSheetPresented = false
    var metaSheet = MemoViewerDetailMetaSheetModel()
    
    var transcludePreviews: [Slashlink: EntryStub] = [:]
    
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
        case .setDetail(let entry):
            return setDetail(
                state: state,
                environment: environment,
                entry: entry
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
            
        case .refreshBacklinks:
            return refreshBacklinks(
                state: state,
                environment: environment
            )
        case .succeedRefreshBacklinks(let backlinks):
            var model = state
            model.backlinks = backlinks
            return Update(state: model)
        case .failRefreshBacklinks(let error):
            logger.error("Failed to refresh backlinks: \(error)")
            return Update(state: state)
           
        case .presentMetaSheet(let isPresented):
            return presentMetaSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .fetchTranscludePreviews:
            return fetchTranscludePreviews(
                state: state,
                environment: environment
            )
        case .succeedFetchTranscludePreviews(let transcludes):
            var model = state
            model.transcludePreviews = transcludes
            return Update(state: model).animation(.easeOutCubic())
            
        case .failFetchTranscludePreviews(let error):
            logger.error("Failed to fetch transcludes: \(error)")
            return Update(state: state)
            
        case .fetchOwnerProfile:
            return fetchOwnerProfile(
                state: state,
                environment: environment
            )
        case .succeedFetchOwnerProfile(let profile):
            var model = state
            model.owner = profile
            return update(
                state: model,
                actions: [
                    .fetchTranscludePreviews,
                    .setMetaSheetAuthor(profile)
                ],
                environment: environment
            ).animation(.easeOutCubic())
        case .failFetchOwnerProfile(let error):
            logger.error("Failed to fetch owner: \(error)")
            return Update(state: state)
        case .succeedIndexBackgroundSphere:
            return succeedIndexBackgroundSphere(
                state: state,
                environment: environment
            )
        case .requestAuthorDetail:
            return update(
                state: state,
                action: .presentMetaSheet(false),
                environment: environment
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
            actions: [
                .setMetaSheetAddress(description.address),
                .fetchOwnerProfile,
                .refreshBacklinks
            ],
            environment: environment
        ).mergeFx(fx)
    }
    
    static func setDetail(
        state: Self,
        environment: Environment,
        entry: MemoEntry?
    ) -> Update<Self> {
        var model = state
        
        // If no response, then mark not found
        guard let entry = entry else {
            model.loadingState = .notFound
            return Update(state: model)
        }
        
        model.loadingState = .loaded
        let memo = entry.contents
        model.address = entry.address
        model.title = memo.title()
        
        let dom = memo.dom()
        
        return update(
            state: model,
            action: .setDom(dom),
            environment: environment
        ).animation(.easeOut)
    }
    
    static func refreshBacklinks(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        guard let address = state.address else {
            return Update(state: state)
        }
        
        let fx: Fx<MemoViewerDetailAction> = Future.detached {
            try await environment.data.readMemoBacklinks(address: address)
        }
        .map { backlinks in
            .succeedRefreshBacklinks(backlinks)
        }
        .recover { error in
            .failRefreshBacklinks(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func setDom(
        state: Self,
        environment: Environment,
        dom: Subtext
    ) -> Update<Self> {
        var model = state
        model.dom = dom
        return update(
            state: model,
            action: .fetchTranscludePreviews,
            environment: environment
        )
    }
    
    static func fetchTranscludePreviews(
        state: MemoViewerDetailModel,
        environment: MemoViewerDetailModel.Environment
    ) -> Update<MemoViewerDetailModel> {
        
        guard let owner = state.owner else {
            return update(
                state: state,
                action: .failFetchTranscludePreviews("Owner profile is not loaded"),
                environment: environment
            )
        }
        
        let links = state.dom.slashlinks
            .compactMap { value in value.toSlashlink() }
        
        let fx: Fx<MemoViewerDetailAction> =
            environment.transclude
            .fetchTranscludePreviewsPublisher(slashlinks: links, owner: owner)
            .map { entries in
                MemoViewerDetailAction.succeedFetchTranscludePreviews(entries)
            }
            .recover { error in
                MemoViewerDetailAction.failFetchTranscludePreviews(error.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func fetchOwnerProfile(
        state: MemoViewerDetailModel,
        environment: MemoViewerDetailModel.Environment
    ) -> Update<MemoViewerDetailModel> {
        let fx: Fx<MemoViewerDetailAction> =
            Future.detached {
                guard let petname = state.address?.toPetname() else {
                     return try await environment
                        .userProfile
                        .requestOurProfile()
                        .profile
                }
                
                let did = try await environment.noosphere.resolve(peer: state.address?.peer)
                
                return try await environment
                    .userProfile
                    .identifyUser(did: did, petname: petname, context: nil)
            }
            .map { profile in
                .succeedFetchOwnerProfile(profile)
            }
            .recover { error in
                .failFetchOwnerProfile(error.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
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
    
    static func succeedIndexBackgroundSphere(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        return update(
            state: state,
            actions: [
                .refreshBacklinks,
                .fetchTranscludePreviews
            ],
            environment: environment
        )
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
        case let .requestAuthorDetail(user):
            return .requestAuthorDetail(user)
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

                For the soul walks upon all paths.
                
                /infinity-paths

                The soul walks not upon a line, neither does it grow like a reed.

                The soul unfolds itself, like a [[lotus]] of countless petals.
                """
            ),
            transcludePreviews: [
                Slashlink("/infinity-paths")!: EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        "/infinity-paths"
                    )!,
                    excerpt: "Say not, \"I have discovered the soul's destination,\" but rather, \"I have glimpsed the soul's journey, ever unfolding along the way.\"",
                    modified: Date.now
                )
            ],
            address: Slashlink(slug: Slug("truth-the-prophet")!),
            backlinks: [],
            send: {
                action in 
            },
            notify: { action in }
        )

        MemoViewerDetailNotFoundView(
            backlinks: [
                EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("@bob/bar")!,
                    excerpt: "The hidden well-spring of your soul must needs rise and run murmuring to the sea; And the treasure of your infinite depths would be revealed to your eyes. But let there be no scales to weigh your unknown treasure; And seek not the depths of your knowledge with staff or sounding line. For self is a sea boundless and measureless.",
                    modified: Date.now
                ),
                EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink("@bob/baz")!,
                    excerpt: "Think you the spirit is a still pool which you can trouble with a staff? Oftentimes in denying yourself pleasure you do but store the desire in the recesses of your being. Who knows but that which seems omitted today, waits for tomorrow?",
                    modified: Date.now
                )
            ],
            notify: {
                action in 
            }
        )
    }
}
