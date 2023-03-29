//
//  BylineLgView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 29/3/2023.
//

import Foundation
import SwiftUI

struct BylineLgView: View {
    var user: UserProfile
    var statistics: UserProfileStatistics?
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.unit3) {
            ProfilePic(image: Image(user.pfp))
            
            VStack(alignment: .leading, spacing: AppTheme.unit) {
                PetnameBylineView(petname: user.petname)
                Text(verbatim: user.bio)
                
                if let statistics = statistics {
                    HStack(spacing: AppTheme.unit2) {
                        ProfileStatisticView(label: "Notes", count: statistics.noteCount)
                        ProfileStatisticView(label: "Backlinks", count: statistics.backlinkCount)
                        ProfileStatisticView(label: "Following", count: statistics.followingCount)
                    }
                    .padding([.top], AppTheme.unit2)
                    .font(.caption)
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

struct BylineLgView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BylineLgView(
                user: UserProfile(petname: Petname("ben")!, pfp: "pfp-dog", bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle.")
            )
            BylineLgView(
                user: UserProfile(petname: Petname("ben")!, pfp: "pfp-dog", bio: "Ploofy snooflewhumps burbled, outflonking the zibber-zabber in a traddlewaddle."),
                statistics: UserProfileStatistics(noteCount: 123, backlinkCount: 64, followingCount: 19)
            )
        }
    }
}
