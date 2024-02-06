//
//  EntryListEmptyView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 6/28/23.
//

import SwiftUI

struct EntryListEmptyView: View {
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
                            Text("Your Subconscious is empty")
                            VStack(spacing: AppTheme.unit) {
                                Text(
                                    "If your mind is empty, it is always ready for anything, it is open to everything. In the beginner's mind there are many possibilities, but in the expert's mind there are few."
                                )
                                .italic()
                                Text(
                                    "Shunryū Suzuki"
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
            .refreshable {
                onRefresh()
            }
        }
    }
}

struct EntryListEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        EntryListEmptyView(
            onRefresh: {}
        )
    }
}
