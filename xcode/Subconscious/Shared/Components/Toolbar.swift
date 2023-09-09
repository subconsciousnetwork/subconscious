//
//  Toolbar.swift
//  Subconscious
//
//  Created by Ben Follington on 9/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct ProfileToolbarItem: ToolbarContent {
    var action: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(
                action: action
            ) {
                Image(systemName: "person")
            }
        }
    }
}

struct SettingsToolbarItem: ToolbarContent {
    var app: Store<AppModel>
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(
                action: {
                    app.send(.presentSettingsSheet(true))
                }
            ) {
                Image(systemName: "gearshape")
            }
        }
    }
}
