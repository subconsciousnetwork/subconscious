//
//  BlockEditorBlockSelectMenu.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/21/23.
//

import SwiftUI
import ObservableStore

extension BlockEditor {
    /// Block select mode menu containing controls to change type and otherwise
    /// interact with blocks.
    struct BlockSelectMenuView: View {
        @Environment(\.colorScheme) private var colorScheme
        @ObservedObject var store: Store<BlockEditor.Model>
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                DragHandleView()
                ScrollView(.horizontal) {
                    HStack(spacing: AppTheme.unit2) {
                        Button(
                            action: {
                                store.send(.becomeTextBlock)
                            },
                            label: {
                                Label(
                                    title: {
                                        Text("Body")
                                    },
                                    icon: {
                                        Image(systemName: "text.alignleft")
                                    }
                                )
                            }
                        )
                        Button(
                            action: {
                                store.send(.becomeHeadingBlock)
                            },
                            label: {
                                Label(
                                    title: {
                                        Text("Heading")
                                    },
                                    icon: {
                                        Image(systemName: "number")
                                    }
                                )
                            }
                        )
                        Button(
                            action: {
                                store.send(.becomeListBlock)
                            },
                            label: {
                                Label(
                                    title: {
                                        Text("List")
                                    },
                                    icon: {
                                        Image(systemName: "list.bullet")
                                    }
                                )
                            }
                        )
                        Button(
                            action: {
                                store.send(.becomeQuoteBlock)
                            },
                            label: {
                                Label(
                                    title: {
                                        Text("Quote")
                                    },
                                    icon: {
                                        Image(systemName: "quote.opening")
                                    }
                                )
                            }
                        )
                        Button(
                            role: .destructive,
                            action: {
                                store.send(.deleteBlock)
                            },
                            label: {
                                Label(
                                    title: {
                                        Text("Delete")
                                    },
                                    icon: {
                                        Image(systemName: "trash")
                                    }
                                )
                            }
                        )
                    }
                    .buttonStyle(PaletteButtonStyle())
                    .padding(AppTheme.unit2)
                }
                .scrollIndicators(.hidden)
                .frame(
                    maxWidth: .infinity
                )
            }
            .padding(.top, AppTheme.unit2)
            .background(.background)
            .cornerRadius(AppTheme.cornerRadiusLg)
            .shadow(style: .brandShadowLg(colorScheme))
        }
    }

}

struct BlockEditorBlockSelectMenuView_Previews: PreviewProvider {
    static var previews: some View {
        BlockEditor.BlockSelectMenuView(
            store: Store(
                state: BlockEditor.Model(),
                environment: AppEnvironment()
            )
        )
    }
}
