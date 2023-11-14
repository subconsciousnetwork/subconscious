//
//  PetnameView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 28/3/2023.
//

import SwiftUI

public enum NameVariant {
    case known(Slashlink, Petname.Name)
    case unknown(Slashlink, Petname.Name)
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
            return NameVariant.known(Slashlink.ourProfile, selfNickname)
        case (_, .following(let petname), _, _):
            return NameVariant.known(self.address, petname)
        case (_, .notFollowing, .some(let selfNickname), _):
            return NameVariant.unknown(self.address, selfNickname)
        case (_, .notFollowing, _, .some(let proposedName)):
            return NameVariant.unknown(self.address, proposedName)
        case _:
            return nil
        }
    }
}

struct AliasView: View {
    var aliases: [Petname]

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

            Text(aliases.map(\.markup).joined(separator: ", "))
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
    var aliases: [Petname] = []
    
    var showMaybePrefix = false
    
    var uniqueAliases: [Petname] {
        switch name {
        case .known(_, let name):
            return aliases
                .filter { alias in
                    name != alias.leaf
                }
                .uniquing(with: \.id)
            
        case _:
            return []
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            switch name {
            case .known(_, let name):
                Text(name.toPetname().markup)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                
                if !uniqueAliases.isEmpty {
                    AliasView(aliases: uniqueAliases)
                }
            case .unknown(let address, let name):
                Text(showMaybePrefix
                     ? "Maybe: \(name.description)"
                     : name.description
                )
                .italic()
                .fontWeight(.medium)
                
                if case let .petname(name) = address.peer {
                    AliasView(aliases: [name])
                }
            }
        }
    }
    
    struct PetnameView_Previews: PreviewProvider {
        static var previews: some View {
            VStack {
                PetnameView(
                    name: .unknown(
                        Slashlink(petname: Petname("melville.bobby.tables")!),
                        Petname.Name("melville")!
                    ),
                    showMaybePrefix: true
                )
                PetnameView(
                    name: .known(
                        Slashlink(petname: Petname("robert")!),
                        Petname.Name("robert")!
                    )
                )
                PetnameView(
                    name: .known(
                        Slashlink(petname: Petname("robert")!),
                        Petname.Name("robert")!
                    ),
                    aliases: [Petname("bob")!, Petname("bobby")!]
                )
            }
        }
    }
}
