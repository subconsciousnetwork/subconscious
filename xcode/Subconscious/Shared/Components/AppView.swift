//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI

//  MARK: View
struct AppView: View {
    @ObservedObject var store: AppStore
    @Environment(\.scenePhase) var scenePhase: ScenePhase
    var isFabPresented: Bool {
        store.state.focus == nil
    }

    var body: some View {
        // Give each element in this ZStack an explicit z-index.
        // This keeps transitions working correctly.
        // SwiftUI will dynamically generate z-indexes when no explicit
        // z-index is given. This can cause transitions to layer incorrectly.
        // Adding an explicit z-index fixed problems with the
        // out-transition for the search view.
        // See https://stackoverflow.com/a/58512696
        // 2021-12-16 Gordon Brander
        ZStack(alignment: .bottomTrailing) {
            Color.background.edgesIgnoringSafeArea(.all)
            if store.state.isReadyForInteraction {
                AppNavigationView(store: store)
                    .zIndex(1)
                Button(
                    action: {
                        withAnimation(
                            .easeOutCubic(duration: Duration.keyboard)
                        ) {
                            store.send(action: .showSearch)
                        }
                    },
                    label: {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 20))
                    }
                )
                .buttonStyle(
                    FABButtonStyle(
                        orbShaderEnabled:
                            store.state.config.orbShaderEnabled
                    )
                )
                .padding()
                .disabled(!isFabPresented)
                .zIndex(2)
                ModalView(
                    isPresented: store.binding(
                        get: \.isSearchShowing,
                        tag: { _ in AppAction.hideSearch },
                        animation: .easeOutCubic(duration: Duration.keyboard)
                    ),
                    content: SearchView(
                        placeholder: "Search or create...",
                        text: store.binding(
                            get: \.searchText,
                            tag: AppAction.setSearch
                        ),
                        focus: store.binding(
                            get: \.focus,
                            tag: AppAction.setFocus
                        ),
                        suggestions: store.binding(
                            get: \.suggestions,
                            tag: AppAction.setSuggestions
                        ),
                        onSelect: { suggestion in
                            store.send(
                                action: .selectSuggestion(suggestion)
                            )
                        },
                        onSubmit: { slug, query in
                            store.send(
                                action: .requestDetail(
                                    slug: slug,
                                    fallback: query
                                )
                            )
                        },
                        onCancel: {
                            withAnimation(
                                .easeOutCubic(duration: Duration.keyboard)
                            ) {
                                store.send(
                                    action: .hideSearch
                                )
                            }
                        }
                    ),
                    keyboardHeight: store.state.keyboardEventualHeight
                )
                .zIndex(3)
            } else {
                ProgressScrimView()
                    .zIndex(4)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .font(Font(UIFont.appText))
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2022-02-08 Gordon Brander
        .onChange(of: self.scenePhase) { phase in
            store.send(action: AppAction.scenePhaseChange(phase))
        }
        .onAppear {
            store.send(action: .appear)
        }
        .environment(\.openURL, OpenURLAction { url in
            store.send(action: .openURL(url))
            return .handled
        })
    }
}
