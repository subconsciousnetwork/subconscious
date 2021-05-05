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

struct TextFieldWithToggleState {
    var text = ""
    var placeholder = ""
    var isEditing = false
    var isToggleActive = false
}

func updateTextFieldWithToggle(
    state: inout TextFieldWithToggleState,
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

struct TextFieldWithToggleView: View {
    var state: TextFieldWithToggleState
    var send: (TextFieldWithToggleAction) -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField(
                state.placeholder,
                text: Binding(
                    get: { state.text },
                    set: { text in send(.setText(text)) }
                ),
                onEditingChanged: { editingChanged in
                    send(.setEditing(editingChanged))
                },
                onCommit: {
                    send(.setText(state.text))
                }
            )
            .onTapGesture(perform: {
                send(.setToggle(isActive: true))
            })
            Group {
                if state.isEditing && !state.text.isEmpty {
                    Button(
                        action: { send(.setText("")) },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.primary)
                        }
                    )
                } else if state.isToggleActive {
                    Button(
                        action: {
                            send(.setToggle(isActive: false))
                        },
                        label: {
                            Image(systemName: "chevron.up.circle")
                                .foregroundColor(.primary)
                        }
                    )
                } else {
                    Button(
                        action: {
                            send(.setToggle(isActive: true))
                        },
                        label: {
                            Image(systemName: "chevron.down.circle")
                                .foregroundColor(.primary)
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
            state: TextFieldWithToggleState(
                placeholder: "Title"
            ),
            send: { action in }
        )
    }
}
