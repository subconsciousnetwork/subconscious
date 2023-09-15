//
//  Toolbar.swift
//  Subconscious
//
//  Created by Ben Follington on 9/9/2023.
//

import Foundation
import SwiftUI
import ObservableStore

struct MainToolbar: ToolbarContent {
    var app: Store<AppModel>
    var profileAction: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(
                action: profileAction
            ) {
                Image(systemName: "person")
            }
        }
        
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
