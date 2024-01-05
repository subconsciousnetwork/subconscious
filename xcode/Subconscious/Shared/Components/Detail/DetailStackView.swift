//
//  DetailStack.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/23.
import SwiftUI
import os
import Combine
import ObservableStore

struct DetailStackView<Root: View>: View {
    @ObservedObject var app: Store<AppModel>
    @Environment (\.colorScheme) var colorScheme
    
    var store: ViewStore<DetailStackModel>
    var root: () -> Root

    var body: some View {
        NavigationStack(
            path: Binding(
                get: { store.state.details },
                send: store.send,
                tag: DetailStackAction.setDetails
            )
        ) {
            root().navigationDestination(
                for: MemoDetailDescription.self
            ) { detail in
                switch detail {
                case .editor(let description):
                    MemoEditorDetailView(
                        app: app,
                        description: description,
                        notify: Address.forward(
                            send: store.send,
                            tag: DetailStackAction.tag
                        )
                    )
                case .viewer(let description):
                    MemoViewerDetailView(
                        app: app,
                        description: description,
                        notify: Address.forward(
                            send: store.send,
                            tag: DetailStackAction.tag
                        )
                    )
                case .profile(let description):
                    UserProfileDetailView(
                        app: app,
                        description: description,
                        notify: Address.forward(
                            send: store.send,
                            tag: DetailStackAction.tag
                        )
                    )
                }
            }
        }
        // Tint using the current detail's highlight color.
        // BUT only for notes.
        .tint(
            (store.state.details.last?.address?.isProfile ?? false)
                ? nil
                : store.state.details.last?.address?.highlightColor(
                    colorScheme: colorScheme
                )
        )
    }
}

extension DetailStackAction {
    /// Generate a detail request from a suggestion
    static func fromSuggestion(_ suggestion: Suggestion) -> Self {
        switch suggestion {
        case let .memo(address, fallback):
            // Determine whether content is ours or theirs, push
            // corresponding memo detail type.
            return .pushDetail(
                MemoDetailDescription.from(
                    address: address,
                    fallback: fallback,
                    defaultAudience: .local
                )
            )
        case let .createLocalMemo(slug, fallback):
            return .pushDetail(
                MemoEditorDetailDescription(
                    address: slug?.toLocalSlashlink(),
                    fallback: fallback,
                    defaultAudience: .local
                )
            )
        case let .createPublicMemo(slug, fallback):
            return .pushDetail(
                MemoEditorDetailDescription(
                    address: slug?.toSlashlink(),
                    fallback: fallback,
                    defaultAudience: .public
                )
            )
        case .random:
            return .pushRandomDetail(autofocus: false)
        }
    }
}

enum DetailStackAction: Hashable {
    /// Set entire navigation stack
    case setDetails([MemoDetailDescription])

    /// Find a detail a given slashlink.
    /// If slashlink has a peer part, this will request
    /// a detail for 3p content.
    /// If slashlink does not have a peer part, this will
    /// request an editor detail.
    case findAndPushDetail(
        address: Slashlink,
        fallback: String?
    )
    
    case findAndPushLinkDetail(EntryLink)
    /// Find a detail for content that belongs to us.
    /// Detail could exist in either local or sphere content.
    case findAndPushMemoEditorDetail(
        slug: Slug,
        fallback: String
    )

    /// Push detail onto navigation stack
    case pushDetail(MemoDetailDescription)

    case requestOurProfileDetail
    case failPushDetail(_ message: String)

    case pushRandomDetail(autofocus: Bool)
    case failPushRandomDetail(String)

    /// Request delete memo.
    /// Gets forwarded up to parent for handling.
    case requestDeleteEntry(Slashlink?)
    /// Deletion attempt failed. Forwarded down from parent.
    case failDeleteMemo(String)
    /// Deletion attempt succeeded. Forwarded down from parent.
    case succeedDeleteMemo(Slashlink)

    case requestSaveEntry(_ entry: MemoEntry)
    case succeedSaveEntry(_ address: Slashlink, _ modified: Date)
    case requestMoveEntry(from: Slashlink, to: Slashlink)
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    case requestMergeEntry(parent: Slashlink, child: Slashlink)
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
    case requestUpdateAudience(_ address: Slashlink, _ audience: Audience)
    case succeedUpdateAudience(_ receipt: MoveReceipt)

    /// Synonym for `.pushDetail` that wraps editor detail in `.editor()`
    static func pushDetail(
        _ detail: MemoEditorDetailDescription
    ) -> Self {
        .pushDetail(.editor(detail))
    }

    /// Synonym for `.pushDetail` that wraps viewer detail in `.viewer()`
    static func pushDetail(
        _ detail: MemoViewerDetailDescription
    ) -> Self {
        .pushDetail(.viewer(detail))
    }
}

struct DetailStackModel: Hashable, ModelProtocol {
    typealias Action = DetailStackAction
    typealias Environment = AppEnvironment

    var details: [MemoDetailDescription] = []

    // Logger for actions
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "DetailStackModel"
    )

    static func update(
        state: Self,
        action: Action,
        environment: Environment
    ) -> Update<DetailStackModel> {
        switch action {
        case let .setDetails(details):
            return setDetails(
                state: state,
                environment: environment,
                details: details
            )
        case let .findAndPushLinkDetail(link):
            return findAndPushLinkDetail(
                state: state,
                environment: environment,
                link: link
            )
        case let .findAndPushDetail(address, fallback):
            return findAndPushDetail(
                state: state,
                environment: environment,
                address: address,
                fallback: fallback
            )
        case let .findAndPushMemoEditorDetail(slug, fallback):
            return findAndPushMemoEditorDetail(
                state: state,
                environment: environment,
                slug: slug,
                fallback: fallback
            )
        case let .pushDetail(detail):
            return pushDetail(
                state: state,
                environment: environment,
                detail: detail
            )
        case let .failPushDetail(error):
            return failPushDetail(
                state: state,
                environment: environment,
                error: error
            )
        case let .pushRandomDetail(autofocus):
            return pushRandomDetail(
                state: state,
                environment: environment,
                autofocus: autofocus
            )
        case let .failPushRandomDetail(error):
            return failPushRandomDetail(
                state: state,
                environment: environment,
                error: error
            )
        case .requestOurProfileDetail:
            return requestOurProfileDetail(
                state: state,
                environment: environment
            )
        case .requestDeleteEntry:
            return noOp(state: state)
        case let .succeedDeleteMemo(address):
            return succeedDeleteMemo(
                state: state,
                environment: environment,
                address: address
            )
        case let .failDeleteMemo(error):
            return failDeleteMemo(
                state: state,
                environment: environment,
                error: error
            )
        // These act as notifications for parent models to react to
        case .requestMoveEntry:
            return noOp(state: state)
        case let .succeedMoveEntry(from, to):
            return succeedMoveEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case .requestMergeEntry:
            return noOp(state: state)
        case let .succeedMergeEntry(parent, child):
            return succeedMergeEntry(
                state: state,
                environment: environment,
                parent: parent,
                child: child
            )
        case .requestSaveEntry:
            return noOp(state: state)
        case .succeedSaveEntry:
            return noOp(state: state)
        case .requestUpdateAudience:
            return noOp(state: state)
        case let.succeedUpdateAudience(receipt):
            return succeedUpdateAudience(
                state: state,
                environment: environment,
                receipt: receipt
            )
        }
    }
    
    static func noOp(state: Self) -> Update<Self> {
        return Update(state: state)
    }

    static func setDetails(
        state: Self,
        environment: Environment,
        details: [MemoDetailDescription]
    ) -> Update<Self> {
        guard state.details != details else {
            return Update(state: state)
        }
        var model = state
        model.details = details
        return Update(state: model)
    }
   
    
    static func findAndPushLinkDetail(
        state: Self,
        environment: Environment,
        link: EntryLink
    ) -> Update<Self> {
        let fx: Fx<DetailStackAction> = Future.detached {
            let address = try await environment.noosphere
                .findBestAddressForLink(link.address)
            return .findAndPushDetail(
                address: address,
                fallback: link.title
            )
        }
        .recover { error in
            logger.error("Failed to resolve peer: \(error)")
            return .findAndPushDetail(
                address: link.address,
                fallback: link.title
            )
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }

    static func findAndPushDetail(
        state: Self,
        environment: Environment,
        address: Slashlink,
        fallback: String?
    ) -> Update<Self> {
        // Intercept profile visits and use the correct view
        guard !address.slug.isProfile else {
            return update(
                state: state,
                action: .pushDetail(
                    .profile(
                        UserProfileDetailDescription(
                            address: address
                        )
                    )
                ),
                environment: environment
            )
        }

        // If slashlink pointing to our sphere, dispatch findAndPushEditDetail
        // to find in local or sphere content and then push editor detail.
        guard address.peer != nil else {
            return update(
                state: state,
                action: .findAndPushMemoEditorDetail(
                    slug: address.toSlug(),
                    fallback: fallback ?? ""
                ),
                environment: environment
            )
        }

        // If slashlink pointing to other sphere, dispatch action
        // for viewer.
        return update(
            state: state,
            action: .pushDetail(
                .viewer(
                    MemoViewerDetailDescription(
                        address: address
                    )
                )
            ),
            environment: environment
        )
    }

    /// Find and push a specific detail for slug
    static func findAndPushMemoEditorDetail(
        state: Self,
        environment: Environment,
        slug: Slug,
        fallback: String
    ) -> Update<Self> {
        let fallbackAddress = slug.toLocalSlashlink()
        let fx: Fx<Action> = environment.data
            .findAddressInOursPublisher(slug: slug)
            .map({ address in
                Action.pushDetail(
                    MemoEditorDetailDescription(
                        address: address ?? fallbackAddress,
                        fallback: fallback
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Push a detail view onto the stack
    static func pushDetail(
        state: Self,
        environment: Environment,
        detail: MemoDetailDescription
    ) -> Update<Self> {
        var model = state
        model.details.append(detail)
        return Update(state: model)
    }


    /// Push a detail view onto the stack
    static func failPushDetail(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        logger.log("Attempt to push invalid detail: \(error)")
        return Update(state: state)
    }

    /// Request detail for a random entry
    static func pushRandomDetail(
        state: Self,
        environment: Environment,
        autofocus: Bool
    ) -> Update<Self> {
        let fx: Fx<Action> = environment.data
            .readRandomEntryLinkPublisher().map({ link in
                Action.pushDetail(
                    MemoEditorDetailDescription(
                        address: link.address,
                        fallback: link.title
                    )
                )
            }).catch({ error in
                Just(
                    Action.failPushRandomDetail(
                        error.localizedDescription
                    )
                )
            }).eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    static func failPushRandomDetail(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        logger.log("Failed to get random note: \(error)")
        return Update(state: state)
    }

    static func requestOurProfileDetail(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        let detail = UserProfileDetailDescription(
            address: Slashlink.ourProfile,
            // Focus following list by default
            // We can already see our recent notes in our notebook so no
            // point showing it again
            initialTabIndex: UserProfileDetailModel.followingTabIndex
        )
        return update(
            state: state,
            action: .pushDetail(.profile(detail)),
            environment: environment
        )
    }
    
    static func succeedDeleteMemo(
        state: Self,
        environment: Environment,
        address: Slashlink
    ) -> Update<Self> {
        logger.debug(
            "Removing deleted memo from detail stack",
            metadata: [
                "address": address.description
            ]
        )
        var model = state
        let details = state.details.filter({ detail in
            detail.address != address
        })
        model.details = details
        return Update(state: model)
    }

    static func failDeleteMemo(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        return Update(state: state)
    }
    
    /// Move success lifecycle handler.
    /// Updates UI in response.
    static func succeedMoveEntry(
        state: Self,
        environment: Environment,
        from: Slashlink,
        to: Slashlink
    ) -> Update<Self> {
        /// Find all instances of this model in the stack and update them
        let details = state.details.map({ (detail: MemoDetailDescription) in
            guard detail.address == from else {
                return detail
            }
            switch detail {
            case .editor(var description):
                description.address = to
                return .editor(description)
            case .viewer(var description):
                description.address = to
                return .viewer(description)
            case .profile(let description):
                return .profile(description)
            }
        })

        return update(
            state: state,
            action: .setDetails(details),
            environment: environment
        )
    }
    
    /// Merge success lifecycle handler.
    /// Updates UI in response.
    static func succeedMergeEntry(
        state: Self,
        environment: Environment,
        parent: Slashlink,
        child: Slashlink
    ) -> Update<Self> {
        /// Find all instances of child and update them to become parent
        let details = state.details.map({ (detail: MemoDetailDescription) in
            guard detail.address == child else {
                return detail
            }
            switch detail {
            case .editor(var description):
                description.address = parent
                return .editor(description)
            case .viewer(var description):
                description.address = parent
                return .viewer(description)
            case .profile(let description):
                return .profile(description)
            }
        })

        return update(
            state: state,
            action: .setDetails(details),
            environment: environment
        )
    }
    
    /// Retitle success lifecycle handler.
    /// Updates UI in response.
    static func succeedUpdateAudience(
        state: Self,
        environment: Environment,
        receipt: MoveReceipt
    ) -> Update<Self> {
        /// Find all instances of this model in the stack and update them
        let details = state.details.map({ (detail: MemoDetailDescription) in
            guard let address = detail.address else {
                return detail
            }
            guard address.slug == receipt.to.slug else {
                return detail
            }
            switch detail {
            case .editor(var description):
                description.address = receipt.to
                return .editor(description)
            case .viewer(var description):
                description.address = receipt.to
                return .viewer(description)
            case .profile(let description):
                return .profile(description)
            }
        })

        return update(
            state: state,
            action: .setDetails(details),
            environment: environment
        )
    }

}

extension DetailStackAction {
    static func tag(_ action: MemoEditorDetailNotification) -> Self {
        switch action {
        case let .requestDelete(address):
            return .requestDeleteEntry(address)
        case let .requestSaveEntry(entry):
            return .requestSaveEntry(entry)
        case let .requestMoveEntry(from, to):
            return .requestMoveEntry(from: from, to: to)
        case let .requestMergeEntry(parent, child):
            return .requestMergeEntry(parent: parent, child: child)
        case let .requestUpdateAudience(address, audience):
            return .requestUpdateAudience(address, audience)
            
        case let .requestDetail(detail):
            return .pushDetail(detail)
        case let .requestFindLinkDetail(link):
            return .findAndPushLinkDetail(link)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedSaveEntry(address, modified):
            return .succeedSaveEntry(address, modified)
        case let .succeedUpdateAudience(receipt):
            return .succeedUpdateAudience(receipt)
        }
    }

    static func tag(_ action: MemoViewerDetailNotification) -> Self {
        switch action {
        case let .requestDetail(detail):
            return .pushDetail(detail)
        case let .requestFindDetail(address, fallback):
            return .findAndPushDetail(address: address, fallback: fallback)
        case let .requestFindLinkDetail(link):
            return .findAndPushLinkDetail(link)
        case let .requestUserProfileDetail(address):
            return .pushDetail(
                MemoDetailDescription.profile(
                    UserProfileDetailDescription(
                        address: address
                    )
                )
            )
        }
    }

    static func tag(_ action: UserProfileDetailNotification) -> Self {
        switch action {
        case let .requestDetail(detail):
            return .pushDetail(detail)
        case let .requestFindLinkDetail(link):
            return .findAndPushLinkDetail(link)
        case let .requestNavigateToProfile(address):
            return .pushDetail(.profile(
                UserProfileDetailDescription(
                    address: address
                )
            ))
        }
    }
}
