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
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var did: String = ""
    @State var petname: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Friend Details")) {
                    // TODO: validation
                    
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.accentColor)
                        TextField("DID", text: $did)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Image(systemName: "at")
                            .foregroundColor(.accentColor)
                        TextField("Petname", text: $petname)
                            .lineLimit(1)
                    }
                    
                }
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // TODO: actually dispatch an action here
                        presentationMode.wrappedValue.dismiss()
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
