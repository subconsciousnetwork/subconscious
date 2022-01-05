//
//  AppNavigationView.swift
//  Subconscious
//
//  Created by Gordon Brander on 9/20/21.
//

import SwiftUI

struct AppNavigationView: View {
    @ObservedObject var store: Store<AppModel>

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack {
                        HStack {
                            Text("Todo")
                            Spacer()
                        }
                    }.padding()
                }.background(Color.background)
                NavigationLink(
                    isActive: store.binding(
                        get: \.isDetailShowing,
                        tag: AppAction.setDetailShowing
                    ),
                    destination: {
                        VStack {
                            if store.state.entryURL == nil {
                                VStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                DetailView(
                                    focus: store.binding(
                                        get: \.focus,
                                        tag: AppAction.setFocus
                                    ),
                                    editorAttributedText: store.binding(
                                        get: \.editorAttributedText,
                                        tag: AppAction.setEditorAttributedText
                                    ),
                                    editorSelection: store.binding(
                                        get: \.editorSelection,
                                        tag: AppAction.setEditorSelection
                                    ),
                                    isLinkSheetPresented: store.binding(
                                        get: \.isLinkSheetPresented,
                                        tag: AppAction.setLinkSheetPresented
                                    ),
                                    linkSearchText: store.binding(
                                        get: \.linkSearchText,
                                        tag: AppAction.setLinkSearchText
                                    ),
                                    linkSuggestions: store.binding(
                                        get: \.linkSuggestions,
                                        tag: AppAction.setLinkSuggestions
                                    ),
                                    backlinks: store.state.backlinks,
                                    onDone: {
                                        store.send(action: .save)
                                    },
                                    onEditorLink: { url, _, range, _ in
                                        store.send(
                                            action: .openEditorURL(
                                                url: url,
                                                range: range
                                            )
                                        )
                                        return false
                                    },
                                    onCommitSearch: { query in
                                        store.send(
                                            action: .commitSearch(query: query)
                                        )
                                    },
                                    onCommitLinkSearch: { query in
                                        store.send(
                                            action: .commitLinkSearch(query)
                                        )
                                    }
                                )
                            }
                        }
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                    },
                    label: {
                        EmptyView()
                    }
                )
            }
            .navigationTitle("Ideas")
            .background(Color.background)
        }
    }
}
