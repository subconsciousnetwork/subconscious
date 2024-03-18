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
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: Logger(
            subsystem: Config.default.rdns,
            category: "MemoViewerDetailStore"
        )
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
            case .loading, .initial:
                MemoViewerDetailLoadingView(
                    notify: notify
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                MemoViewerDetailLoadedView(
                    store: store,
                    address: description.address,
                    notify: notify
                )
            case .notFound:
                MemoViewerDetailNotFoundView(
                    backlinks: store.state.backlinks,
                    notify: notify
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .tint(store.state.themeColor?.toHighlightColor())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(AppThemeToolbarViewModifier())
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
    
    var body: some View {
        ScrollView {
            NotFoundView()
                .padding(.bottom, AppTheme.unit4)
            
            BacklinksView(
                backlinks: backlinks,
                onLink: { link in
                    notify(.requestFindLinkDetail(link))
                }
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
    @ObservedObject var store: Store<MemoViewerDetailModel>
    var address: Slashlink
    var notify: (MemoViewerDetailNotification) -> Void
    
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoViewerDetailLoadedView"
    )
    
    var background: Color? {
        store.state.themeColor?.toColor()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let author = store.state.owner,
                       let name = author.toNameVariant() {
                        Button(
                            action: {
                                store.send(.requestAuthorDetail(author))
                            },
                            label: {
                                HStack(
                                    alignment: .center,
                                    spacing: AppTheme.unit3
                                ) {
                                    ProfilePic(
                                        pfp: author.pfp,
                                        size: .large
                                    )
                                    
                                    PetnameView(
                                        name: name,
                                        aliases: [],
                                        showMaybePrefix: false
                                    )
                                }
                                .transition(
                                    .push(
                                        from: .bottom
                                    )
                                )
                            }
                        )
                        .padding(AppTheme.padding)
                        
                    }
                    VStack {
                        SubtextView(
                            peer: store.state.owner?.address.peer,
                            subtext: store.state.dom,
                            transcludePreviews: store.state.transcludePreviews,
                            onLink: { link in
                                notify(.requestFindLinkDetail(link))
                            }
                        ).textSelection(
                            .enabled
                        )
                        
                        Spacer()
                        
                        if let address = store.state.address {
                            HStack {
                                Spacer()
                                
                                LikeButtonView(
                                    liked: store.state.liked,
                                    action: {
                                        notify(
                                            .requestUpdateLikeStatus(
                                                address,
                                                liked: !store.state.liked
                                            )
                                        )
                                    }
                                )
                            }
                        }
                    }
                    .padding(DeckTheme.cardPadding)
                    .frame(
                        minHeight: UIFont.appTextMono.lineHeight * 8
                    )
                    .background(background)
                    .cornerRadius(DeckTheme.cornerRadius, corners: .allCorners)
                    .shadow(style: .transclude)
                    .padding(.bottom, AppTheme.unit4)
                    .padding(.top, AppTheme.unit2)
                    
                    AICommentsView(
                        comments: store.state.comments,
                        onRefresh: {
                            store.send(.refreshComments)
                        },
                        onRespond: { comment in
                            notify(.requestQuoteInNewDetail(address, comment: comment))
                        },
                        background: background ?? .secondary
                    )
                    
                    BacklinksView(
                        backlinks: store.state.backlinks,
                        onLink: { link in
                            notify(.requestFindLinkDetail(link))
                        }
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
        address: Slashlink,
        fallback: String?
    )
    case requestFindLinkDetail(EntryLink)
    case requestUserProfileDetail(_ address: Slashlink)
    case requestQuoteInNewDetail(_ address: Slashlink, comment: String? = nil)
    case requestUpdateLikeStatus(_ address: Slashlink, liked: Bool)
    case selectAppendLinkSearchSuggestion(AppendLinkSuggestion)
}

extension MemoViewerDetailNotification {
    static func from(_ action: MemoViewerDetailAction) -> Self? {
        switch action {
        case let .requestAuthorDetail(user):
            return .requestUserProfileDetail(user.address)
        case let .requestQuoteInNewNote(address, comment):
            return .requestQuoteInNewDetail(address, comment: comment)
        case let .requestUpdateLikeStatus(address, liked):
            return .requestUpdateLikeStatus(address, liked: liked)
        case let .selectAppendLinkSearchSuggestion(suggestion):
            return .selectAppendLinkSearchSuggestion(suggestion)
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
    case metaSheet(MemoViewerDetailMetaSheetAction)
    case appear(_ description: MemoViewerDetailDescription)
    case refreshAll
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
    case requestQuoteInNewNote(_ address: Slashlink, comment: String? = nil)
    case requestUpdateLikeStatus(_ address: Slashlink, liked: Bool)
    
    case refreshLikedStatus
    case succeedRefreshLikedStatus(_ liked: Bool)
    case failRefreshFetchLikedStatus(_ error: String)
    
    case refreshComments
    case succeedRefreshComments(_ comments: [String])
    case failRefreshComments(_ error: String)
    
    case selectAppendLinkSearchSuggestion(AppendLinkSuggestion)
    
    /// Synonym for `.metaSheet(.setAddress(_))`
    static func setMetaSheetAddress(_ address: Slashlink) -> Self {
        .metaSheet(.setAddress(address))
    }
    static func setMetaSheetAuthor(_ author: UserProfile) -> Self {
        .metaSheet(.setAuthor(author))
    }
    static func setMetaSheetLiked(_ liked: Bool) -> Self {
        .metaSheet(.setLiked(liked))
    }
}

/// React to actions from the root app store
extension MemoViewerDetailAction {
    static func fromAppAction(
        _ action: AppAction
    ) -> MemoViewerDetailAction? {
        switch (action) {
        case .succeedIndexOurSphere, .completeIndexPeers:
            return .succeedIndexBackgroundSphere
        case .succeedSyncSphereWithGateway:
            return .refreshAll
        case .succeedUpdateLikeStatus:
            return .refreshLikedStatus
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
    var liked: Bool = false
    var backlinks: [EntryStub] = []
    var headers: WellKnownHeaders? = nil
    var themeColor: ThemeColor? {
        headers?.themeColor ?? address?.themeColor
    }
    
    var comments: [String] = []
    
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
                environment: environment
            )
        case .appear(let description):
            return appear(
                state: state,
                environment: environment,
                description: description
            )
        case .refreshAll:
            return refreshAll(
                state: state,
                environment: environment
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
            return Update(state: model).animation(.easeOutCubic())
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
        case let .succeedFetchOwnerProfile(profile):
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
        case .requestQuoteInNewNote:
            return update(
                state: state,
                action: .presentMetaSheet(false),
                environment: environment
            )
        case .requestUpdateLikeStatus:
            return update(
                state: state,
                action: .presentMetaSheet(false),
                environment: environment
            )
        case .refreshLikedStatus:
            return refreshLikedStatus(
                state: state,
                environment: environment
            )
        case let .succeedRefreshLikedStatus(liked):
            var model = state
            model.liked = liked
            return update(
                state: model,
                action: .metaSheet(.setLiked(liked)),
                environment: environment
            )
        case let .failRefreshFetchLikedStatus(error):
            logger.error("Failed to refresh liked status: \(error)")
            return Update(state: state)
        case let .selectAppendLinkSearchSuggestion(suggestion):
            return update(
                state: state,
                actions: [
                    .metaSheet(.selectAppendLinkSearchSuggestion(suggestion)),
                    .presentMetaSheet(false)
                ],
                environment: environment
            )
        case .refreshComments:
            return refreshComments(
                state: state,
                environment: environment
            )
        case let .succeedRefreshComments(comments):
            return succeedRefreshComments(
                state: state,
                environment: environment,
                comments: comments
            )
        case let .failRefreshComments(error):
            logger.error("Failed to refresh comments: \(error)")
            return Update(state: state)
        }
    }
    
    static func appear(
        state: Self,
        environment: Environment,
        description: MemoViewerDetailDescription
    ) -> Update<Self> {
        guard state.address != description.address else {
            logger.log("Attempted to appear with same address, doing nothing")
            return Update(state: state)
        }
        
        var model = state
        model.address = description.address
        
        return update(
            state: model,
            // Set meta sheet address as well
            actions: [
                .setMetaSheetAddress(description.address),
                .refreshComments,
                .refreshAll
            ],
            environment: environment
        )
    }
    
    static func refreshAll(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        guard let address = state.address else {
            logger.log("Attempted to refresh with nil address")
            return Update(state: state)
        }
        
        var model = state
        model.loadingState = .loading
        
        let fx: Fx<Action> = environment.data.readMemoDetailPublisher(
            address: address
        ).map({ response in
            Action.setDetail(response)
        }).eraseToAnyPublisher()
        return update(
            state: model,
            actions: [
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
            return Update(state: model).animation(.easeOutCubic())
        }
        
        model.loadingState = .loaded
        let memo = entry.contents
        model.address = entry.address
        model.title = memo.title()
        model.headers = memo.wellKnownHeaders()
        
        let dom = memo.dom()
        
        return update(
            state: model,
            actions: [
                .setDom(dom),
                .metaSheet(.setShareableText(entry.contents.description)),
                .refreshLikedStatus
            ],
            environment: environment
        ).animation(.easeOutCubic())
    }
    
    static func refreshLikedStatus(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        guard let address = state.address else {
            return Update(state: state)
        }
        
        let fx: Fx<MemoViewerDetailAction> = Future.detached {
            let liked = try await environment.userLikes.isLikedByUs(address: address)
            return .succeedRefreshLikedStatus(liked)
        }
        .recover { error in
            .failRefreshFetchLikedStatus(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
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
        
        let fx: Fx<MemoViewerDetailAction> = environment.transclude
            .fetchTranscludesPublisher(
                slashlinks: links,
                owner: owner
            )
            .map { entries in
                MemoViewerDetailAction.succeedFetchTranscludePreviews(entries)
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
                guard let address = state.address else {
                    return .failFetchOwnerProfile("Missing address")
                }
                
                let petname = address.toPetname()
                let did = try await environment.noosphere.resolve(peer: state.address?.peer)
                
                let profile = try await Func.run {
                    guard petname != nil else {
                        return try await environment
                           .userProfile
                           .loadOurFullProfileData()
                           .profile
                    }
                    
                    return try await environment
                        .userProfile
                        .identifyUser(did: did, petname: petname, context: nil)
                }
                
                return .succeedFetchOwnerProfile(profile)
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
    
    static func refreshComments(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        let fx: Fx<MemoViewerDetailAction> = Future.detached {
            var comments: [String] = []
            
            for _ in 0...2 {
                let comment = await environment.prompt.generate(
                    input: state.dom.description
                )
                comments.append(comment)
            }
            
            return comments.uniquing()
        }
        .map { comments in
            .succeedRefreshComments(comments)
        }
        .recover { error in
            .failRefreshComments(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedRefreshComments(
        state: Self,
        environment: Environment,
        comments: [String]
    ) -> Update<Self> {
        var model = state
        model.comments = comments
        return Update(state: model).animation(.easeOutCubic())
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
        case let .requestQuoteInNewNote(address, comment):
            return .requestQuoteInNewNote(address, comment: comment)
        case let .requestUpdateLikeStatus(address, liked):
            return .requestUpdateLikeStatus(address, liked: liked)
        case let .selectAppendLinkSearchSuggestion(suggestion):
            return .selectAppendLinkSearchSuggestion(suggestion)
        default:
            return .metaSheet(action)
        }
    }
}

struct MemoViewerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MemoViewerDetailLoadedView(
            store: Store(
                state: MemoViewerDetailModel(
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
                            excerpt: Subtext(
                                markup: "Say not, \"I have discovered the soul's destination,\" but rather, \"I have glimpsed the soul's journey, ever unfolding along the way.\""
                            ),
                            headers: .emptySubtext
                        )
                    ]
                ),
                environment: AppEnvironment()
            ),
            address: Slashlink(slug: Slug("truth-the-prophet")!),
            notify: { action in }
        )

        MemoViewerDetailNotFoundView(
            backlinks: [
                EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        "@bob/bar"
                    )!,
                    excerpt: Subtext(
                        markup: "The hidden well-spring of your soul must needs rise and run murmuring to the sea; And the treasure of your infinite depths would be revealed to your eyes. But let there be no scales to weigh your unknown treasure; And seek not the depths of your knowledge with staff or sounding line. For self is a sea boundless and measureless."
                    ),
                    headers: .emptySubtext
                ),
                EntryStub(
                    did: Did.dummyData(),
                    address: Slashlink(
                        "@bob/baz"
                    )!,
                    excerpt: Subtext(
                        markup: "Think you the spirit is a still pool which you can trouble with a staff? Oftentimes in denying yourself pleasure you do but store the desire in the recesses of your being. Who knows but that which seems omitted today, waits for tomorrow?"
                    ),
                    headers: .emptySubtext
                )
            ],
            notify: {
                action in 
            }
        )
    }
}
