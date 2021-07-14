//
//  EditorTitleView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 5/5/21.
//

import SwiftUI
import Combine

enum TextFieldWithToggleAction {
    case setEditing(_ isEditing: Bool)
    case setText(_ text: String)
    case setToggle(isActive: Bool)
}

struct TextFieldWithToggleModel: Equatable {
    var text = ""
    var placeholder = ""
    var isEditing = false
    var isToggleActive = false
}

func updateTextFieldWithToggle(
    state: inout TextFieldWithToggleModel,
    action: TextFieldWithToggleAction
) -> AnyPublisher<TextFieldWithToggleAction, Never> {
    switch action {
    case .setText(let text):
        state.text = text
    case .setEditing(let isEditing):
        state.isEditing = isEditing
    case .setToggle(let isActive):
        state.isToggleActive = isActive
    }
    return Empty().eraseToAnyPublisher()
}

struct TextFieldWithToggleView: View, Equatable {
    let store: ViewStore<TextFieldWithToggleModel, TextFieldWithToggleAction>

    var body: some View {
        HStack(spacing: 8) {
            TextField(
                store.state.placeholder,
                text: Binding(
                    get: { store.state.text },
                    set: { text in store.send(.setText(text)) }
                ),
                onEditingChanged: { editingChanged in
                    store.send(.setEditing(editingChanged))
                },
                onCommit: {
                    store.send(.setText(store.state.text))
                }
            )
            .onTapGesture(perform: {
                store.send(.setToggle(isActive: true))
            })
            Group {
                if store.state.isEditing && !store.state.text.isEmpty {
                    Button(
                        action: { store.send(.setText("")) },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.Sub.secondaryIcon)
                        }
                    )
                } else if store.state.isToggleActive {
                    Button(
                        action: {
                            store.send(.setToggle(isActive: false))
                        },
                        label: {
                            Image(systemName: "chevron.up.circle")
                                .foregroundColor(.Sub.secondaryIcon)
                        }
                    )
                } else {
                    Button(
                        action: {
                            store.send(.setToggle(isActive: true))
                        },
                        label: {
                            Image(systemName: "chevron.down.circle")
                                .foregroundColor(.Sub.secondaryIcon)
                        }
                    )
                }
            }
        }
    }
}

struct EditorTitleView_Previews: PreviewProvider {
    static var previews: some View {
        TextFieldWithToggleView(
            store: ViewStore(
                state: TextFieldWithToggleModel(
                    placeholder: "Title"
                ),
                send: { action in }
            )
        )
    }
}
