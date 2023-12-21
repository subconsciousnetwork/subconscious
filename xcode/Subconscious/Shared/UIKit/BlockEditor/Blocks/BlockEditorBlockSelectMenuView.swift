//
//  BlockEditorBlockSelectMenu.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 12/21/23.
//

import SwiftUI

extension BlockEditor {
    /// Actions for block select menu
    enum BlockSelectMenuAction {
        case becomeTextBlock
        case becomeHeadingBlock
        case becomeListBlock
        case becomeQuoteBlock
    }
}

extension BlockEditor {
    /// Block select mode menu containing controls to change type and otherwise
    /// interact with blocks.
    struct BlockSelectMenuView: View {
        @Environment(\.colorScheme) private var colorScheme
        @State private var dragOffsetY: CGFloat = 0
        @GestureState private var dragGesture: CGFloat = 0
        var dragThreshold: CGFloat = 100
        var send: (BlockSelectMenuAction) -> Void

        var body: some View {
            VStack(alignment: .center, spacing: AppTheme.unit2) {
                DragHandleView()
                HStack(spacing: AppTheme.unit2) {
                    Button(
                        action: {
                            send(.becomeTextBlock)
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
                            send(.becomeHeadingBlock)
                        },
                        label: {
                            Label(
                                title: {
                                    Text("Heading")
                                },
                                icon: {
                                    Image(systemName: "textformat.size.larger")
                                }
                            )
                        }
                    )
                    Button(
                        action: {
                            send(.becomeListBlock)
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
                            send(.becomeQuoteBlock)
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
                    Spacer()
                }
                .buttonStyle(PaletteButtonStyle())
                .frame(
                    maxWidth: .infinity
                )
            }
            .padding(AppTheme.unit2)
            .background(.background)
            .cornerRadius(AppTheme.cornerRadiusLg)
            .shadow(style: .brandShadowLg(colorScheme))
            .animation(.interactiveSpring(), value: dragGesture)
            .offset(y: dragOffsetY + dragGesture)
            .gesture(
                DragGesture()
                    .updating(
                        $dragGesture,
                        body: { gesture, state, transaction in
                            state = gesture.translation.height
                        }
                    )
                    .onEnded({ gesture in
                        if gesture.predictedEndTranslation.height >
                            dragThreshold
                        {
                            self.dragOffsetY = 300
                        } else {
                            self.dragOffsetY = 0
                        }
                    })
            )
        }
    }

}

struct BlockEditorBlockSelectMenuView_Previews: PreviewProvider {
    static var previews: some View {
        BlockEditor.BlockSelectMenuView(
            send: { action in }
        )
    }
}
