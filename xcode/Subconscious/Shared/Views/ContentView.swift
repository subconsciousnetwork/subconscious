//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appModel = AppModel()
    @State private var isEditPresented = false
    @State private var isSearchOpen = false
    @State private var editorText = ""
    @State private var editorTitle = ""

    func invokeEdit(title: String, text: String) {
        self.isEditPresented = true
        self.editorTitle = title
        self.editorText = text
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if !appModel.comittedQuery.isEmpty {
                    Button(action: {
                        appModel.comittedQuery = ""
                        appModel.liveQuery = ""
                        self.isSearchOpen = false
                    }) {
                        Icon(image: Image(systemName: "chevron.left"))
                    }
                }
                SearchBarView(
                    comittedQuery: $appModel.comittedQuery,
                    liveQuery: $appModel.liveQuery,
                    isOpen: $isSearchOpen
                )
            }
            .padding(8)
            Divider()
            ZStack {
                Group {
                    if appModel.comittedQuery.isEmpty {
                        StreamView()
                    } else {
                        SearchView(
                            threads: $appModel.threads
                        )
                    }
                }

                PinBottomRight {
                    Button(action: {
                        self.invokeEdit(
                            title: "",
                            text: ""
                        )
                    }) {
                        ActionButton()
                    }
                }

                VStack {
                    if isSearchOpen {
                        ResultListView(
                            results: appModel.results
                        ) { result in
                            appModel.comittedQuery = result.text
                            appModel.liveQuery = result.text
                            self.isSearchOpen = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isEditPresented) {
            Editor(
                title: $editorTitle,
                text: $editorText,
                isPresented: $isEditPresented
            )
        }
        .environmentObject(appModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
