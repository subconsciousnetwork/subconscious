//
//  DidView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 3/3/2023.
//

import Foundation
import SwiftUI

struct DidView: View {
    var did: Did
    var qrCode: Bool = false
    var qrCodeSize: CGFloat = 256
    
    var body: some View {
        VStack {
            if qrCode {
                DidQrCodeView(did: did, color: .accentColor)
                    .frame(maxWidth: qrCodeSize, alignment: .center)
            }
            
            ShareLink(item: did.did) {
                HStack {
                    Text(did.did)
                        .font(.callout.monospaced())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: AppTheme.unit2)
                        Image(systemName: "square.and.arrow.up")
                    }
            }
        }
    }
}

struct Previews_DidView_Previews: PreviewProvider {
    static var previews: some View {
        DidView(did: Did("did:key:z6MkmCJAZansQ3p1Qwx6wrF4c64yt2rcM8wMrH5Rh7DGb2K7")!)
    }
}
