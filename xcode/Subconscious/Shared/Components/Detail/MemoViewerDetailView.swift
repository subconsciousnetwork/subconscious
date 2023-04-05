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
            if store.state.isLoading {
                MemoViewerDetailLoadingView(
                    notify: notify
                )
            } else {
                MemoViewerDetailLoadedView(
                    title: store.state.title,
                    editor: store.state.editor,
                    backlinks: store.state.backlinks,
                    send: store.send,
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
                        onLink: { link in true }
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

/// Actions forwarded up to the parent context to notify it of specific
/// lifecycle events that happened within our component.
enum MemoViewerDetailNotification: Hashable {
    case requestDetail(_ description: MemoDetailDescription)
}

/// A description of a memo detail that can be used to set up the memo
/// detal's internal state.
struct MemoViewerDetailDescription: Hashable {
    var address: MemoAddress
}

enum MemoViewerDetailAction: Hashable {
    case editor(SubtextTextAction)
    case appear(_ description: MemoViewerDetailDescription)
    case setDetail(_ detail: MemoDetailResponse?)
    case failLoadDetail(_ message: String)
}

struct MemoViewerDetailModel: ModelProtocol {
    typealias Action = MemoViewerDetailAction
    typealias Environment = AppEnvironment

    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "MemoViewerDetail"
    )
    
    var isLoading = true
    var address: MemoAddress?
    var defaultAudience = Audience.local
    var title = ""
    var editor = SubtextTextModel(isEditable: false)
    var backlinks: [EntryStub] = []
    
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
        }
    }
    
    static func appear(
        state: Self,
        environment: Environment,
        description: MemoViewerDetailDescription
    ) -> Update<Self> {
        var model = state
        model.isLoading = true
        model.address = description.address
        let fx: Fx<Action> = environment.data.readMemoDetailAsync(
            address: description.address
        ).map({ response in
            Action.setDetail(response)
        }).eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    static func setDetail(
        state: Self,
        environment: Environment,
        response: MemoDetailResponse?
    ) -> Update<Self> {
        var model = state
        model.isLoading = false
        // TODO handle loading state
        guard let response = response else {
            return Update(state: model)
        }
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
            backlinks: [],
            send: { action in },
            notify: { action in }
        )
    }
}
