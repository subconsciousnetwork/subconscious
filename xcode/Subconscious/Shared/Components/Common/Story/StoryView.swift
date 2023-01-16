//
//  StoryView.swift
//  Subconscious
//
//  Created by Gordon Brander on 8/24/22.
//

import SwiftUI

/// Wrapper view for various types of story view
struct StoryView: View {
    var story: Story
    var action: (EntryLink, String) -> Void

    var body: some View {
        switch story {
        case .prompt(let storyPrompt):
            StoryPromptView(
                story: storyPrompt,
                action: action
            )
        case .combo(let combo):
            StoryComboView(
                story: combo,
                action: action
            )
        }
    }
}

