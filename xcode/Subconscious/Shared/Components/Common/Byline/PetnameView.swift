//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

public enum NameVariant {
    case petname(Slashlink, Petname.Name)
    case proposedName(Slashlink, Petname.Name)
    case selfNickname(Slashlink, Petname.Name)
}

extension UserProfile {
    func toNameVariant() -> NameVariant? {
        switch (
            self.category,
            self.ourFollowStatus,
            self.nickname,
            self.address.petname?.leaf
        ) {
        case (.ourself, _, .some(let selfNickname), _):
            return NameVariant.petname(Slashlink.ourProfile, selfNickname)
        case (_, .following(let petname), _, _):
            return NameVariant.petname(self.address, petname)
        case (_, .notFollowing, .some(let selfNickname), _):
            return NameVariant.selfNickname(self.address, selfNickname)
        case (_, .notFollowing, _, .some(let proposedName)):
            return NameVariant.proposedName(self.address, proposedName)
        case _:
            return nil
        }
    }
}

struct PeerView: View {
    var peer: Peer

    var body: some View {
        HStack(spacing: AppTheme.unit) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                    .foregroundColor(.secondaryBackground)
                Text("AKA")
                    .foregroundColor(.secondary)
                    .font(.system(size: 10))
            }
            .frame(width: 28, height: 15)

            Text(peer.markup)
                .foregroundColor(.secondary)
                .fontWeight(.regular)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

/// Byline style for displaying a petname
struct PetnameView: View {
    var name: NameVariant
    var showMaybePrefix = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            switch name {
            case .petname(let address, let name):
                Text(name.toPetname().markup)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                
                /// Prevent showing _exactly_ the same name above and below e.g.
                /// @bob
                /// AKA @bob
                ///
                /// We still permit:
                /// @bob
                /// AKA @bob.alice
                if let peer = address.peer,
                   let petname = address.petname,
                   petname != name.toPetname() {
                    PeerView(peer: peer)
                }
            case .selfNickname(let address, let name),
                 .proposedName(let address, let name):
                Text(showMaybePrefix
                     ? "Maybe: \(name.description)"
                     : name.description
                )
                .italic()
                .fontWeight(.medium)
                
                if let peer = address.peer {
                    PeerView(peer: peer)
                }
            }
        }
    }
    
    
    
    struct PetnameView_Previews: PreviewProvider {
        static var previews: some View {
            VStack {
                PetnameView(
                    name: .selfNickname(
                        Slashlink(petname: Petname("melville.bobby.tables")!),
                        Petname.Name("melville")!
                    )
                )
                PetnameView(
                    name: .proposedName(
                        Slashlink(petname: Petname("melville.bobby.tables")!),
                        Petname.Name("melville")!
                    ),
                    showMaybePrefix: true
                )
                PetnameView(
                    name: .petname(
                        Slashlink(petname: Petname("robert")!),
                        Petname.Name("robert")!
                    )
                )
            }
        }
    }
}
