//
//  StoryAudienceInfoView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/16/23.
//

import SwiftUI

struct StoryAudienceView: View {
    var audience: Audience

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                switch audience {
                case .public:
                    StoryAudienceTemplateView(
                        icon: Image(systemName: "network"),
                        text: Text("**Public**: everyone can see this")
                    )
                case .local:
                    StoryAudienceTemplateView(
                        icon: Image(systemName: "eye.fill"),
                        text: Text("**Local**: only you can see this")
                    )
                }
                Spacer()
            }
            .padding(.horizontal, AppTheme.padding)
            .padding(.vertical, AppTheme.unit)
            Divider()
        }
    }
}

struct StoryAudienceTemplateView: View {
    var icon: Image
    var text: Text

    var body: some View {
        HStack {
            icon.frame(width: 20, height: 20)
            text
        }
        .foregroundColor(.secondary)
        .font(.caption)
    }
}

struct StoryAudienceInfoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            StoryAudienceView(audience: .public)
            StoryAudienceView(audience: .local)
        }
    }
}
