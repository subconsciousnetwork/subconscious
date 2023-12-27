//
//  FeedEmptyView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 13/10/2023.
//

import SwiftUI

struct FeedEmptyView: View {
    var onRefresh: () -> Void

    var body: some View {
        GeometryReader { geom in
            ScrollView {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: AppTheme.unit * 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 64))
                            VStack(spacing: AppTheme.unit) {
                                Text("Your feed is empty.")
                                Text("When you follow others their notes will appear here.")
                            }
                            
                            VStack(spacing: AppTheme.unit) {
                                Text(
                                    """
                                    Become totally empty
                                    Quiet the restlessness of the mind
                                    Only then will you witness everything unfolding from emptiness.
                                    """
                                )
                                .italic()
                                Text(
                                    "Lao Tzu"
                                )
                            }
                            .frame(width: 240)
                            .font(.caption)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .multilineTextAlignment(.center)
                .padding()
                .frame(minHeight: geom.size.height)
            }
            .foregroundColor(Color.secondary)
            .background(Color.background)
            .refreshable {
                onRefresh()
            }
        }
    }
}

struct FeedEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        FeedEmptyView(
            onRefresh: {}
        )
    }
}
