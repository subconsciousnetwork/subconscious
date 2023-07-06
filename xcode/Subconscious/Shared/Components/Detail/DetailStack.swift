//
//  DetailStack.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/23.
//
//  This file defines a model and actions, but not view. Instead, you can
//  use the model and actions to drive a `NavigationStack`.

import SwiftUI
import os
import Combine
import ObservableStore

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
        link: SubSlashlinkLink
    )
    
    /// Find a detail for content that belongs to us.
    /// Detail could exist in either local or sphere content.
    case findAndPushMemoEditorDetail(
        slug: Slug,
        fallback: String
    )
    
    /// Push detail onto navigation stack
    case pushDetail(MemoDetailDescription)
    
    case requestOurProfileDetail
    case pushOurProfileDetail(UserProfile)
    case failPushDetail(_ message: String)
    
    case pushRandomDetail(autofocus: Bool)
    case failPushRandomDetail(String)
    
    
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
    
    var details: [MemoDetailDescription]
    
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
        case let .findAndPushDetail(address, link):
            return findAndPushDetail(
                state: state,
                environment: environment,
                address: address,
                link: link
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
        case .pushOurProfileDetail(let user):
            return pushOurProfileDetail(
                state: state,
                environment: environment,
                user: user
            )
        }
    }
    
    static func setDetails(
        state: Self,
        environment: Environment,
        details: [MemoDetailDescription]
    ) -> Update<Self> {
        var model = state
        model.details = details
        return Update(state: model)
    }
    
    static func findAndPushDetail(
        state: Self,
        environment: Environment,
        address: Slashlink,
        link: SubSlashlinkLink
    ) -> Update<Self> {
        // Stitch the base address on to the tapped link, making any
        // bare slashlinks relative to the sphere they belong to.
        //
        // This is needed in the viewer but address will always based
        // on our sphere in the editor case.
        let slashlink: Slashlink = Func.run {
            guard case let .petname(basePetname) = address.peer else {
                return link.slashlink
            }
            return link.slashlink.rebaseIfNeeded(petname: basePetname)
        }
        // Intercept profile visits and use the correct view
        guard !slashlink.slug.isProfile else {
            return update(
                state: state,
                action: .pushDetail(
                    .profile(
                        UserProfileDetailDescription(
                            address: slashlink
                        )
                    )
                ),
                environment: environment
            )
        }
        
        // If slashlink pointing to our sphere, dispatch findAndPushEditDetail
        // to find in local or sphere content and then push editor detail.
        guard slashlink.peer != nil else {
            return update(
                state: state,
                action: .findAndPushMemoEditorDetail(
                    slug: slashlink.toSlug(),
                    fallback: link.fallback
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
                        address: slashlink
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
        let fx: Fx<Action> = environment.userProfile
            .loadOurProfileFromMemoPublisher()
            .map { user in
                Action.pushOurProfileDetail(user)
            }
            .recover { error in
                Action.failPushDetail(error.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func pushOurProfileDetail(
        state: Self,
        environment: Environment,
        user: UserProfile
    ) -> Update<Self> {
        let detail = UserProfileDetailDescription(
            address: Slashlink.ourProfile,
            user: user,
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
}

