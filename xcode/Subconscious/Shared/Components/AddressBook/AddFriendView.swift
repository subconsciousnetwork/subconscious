//
//  AddFriendView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 2/27/23.
//

import SwiftUI
import ObservableStore

struct AddFriendView: View {
    @ObservedObject var app: Store<AppModel>
    var unknown = "Unknown"
    
    @State var did: String = ""
    @State var petname: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Friend Details")) {
                    // TODO: validation
                    TextField("DID", text: $did)
                        .lineLimit(1)
                    TextField("Petname", text: $petname)
                        .lineLimit(1)
                }
                
                Section(header: Text("Add via QR Code")) {
                    Button("Scan Code") {
                        
                    }
                }
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        app.send(.presentSettingsSheet(false))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        app.send(.presentSettingsSheet(false))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendView(
            app: Store(
                state: AppModel(),
                environment: AppEnvironment()
            )
        )
    }
}
