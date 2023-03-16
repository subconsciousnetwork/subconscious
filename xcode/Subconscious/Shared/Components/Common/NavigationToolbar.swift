//
//  NavigationToolbar.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/19/22.
//

import SwiftUI

/// A pseudo-toolbar similar to the one offered by NavigationView
struct NavigationToolbar<Principal, Leading, Trailing>: View
where Principal: View, Leading: View, Trailing: View {
    var principal: () -> Principal
    var leading: () -> Leading
    var trailing: () -> Trailing
    var body: some View {
        HStack(alignment: .center) {
            HStack {
                leading()
            }
            .frame(minWidth: Unit.unit * 20, alignment: .leading)
            Spacer()
            HStack {
                principal()
            }
            .frame(maxWidth: .infinity)
            Spacer()
            HStack {
                trailing()
            }
            .frame(minWidth: Unit.unit * 20, alignment: .trailing)
        }
    }
}

struct NavigationToolbar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationToolbar(
            principal: { Text("Title") },
            leading: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}
