//
//  GenerativeProfilePic.swift
//  Subconscious
//
//  Created by Ben Follington on 25/4/2023.
//

import SwiftUI

struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
    init(seed: Int) { srand48(seed) }
    func next() -> UInt64 { return UInt64(drand48() * Double(UInt64.max)) }
}

struct GenerativeProfilePicParams {
    var sigil: String
    var blendMode: BlendMode
    var color: Color
    var gradient: [Gradient.Stop]
}

extension GenerativeProfilePicParams {
    init(did: Did) {
        var rng = RandomNumberGeneratorWithSeed(seed: did.hashValue)
        
        self.sigil =
            [
                "✶",
                "✴︎",
                "✸",
                "✺",
                "✦",
                "✷",
                "☾",
                "♦︎",
                "♢",
            ]
            .randomElement(using: &rng) ?? ""
        
        self.color =
            [
                Color.blue,
                Color.gray,
                Color.cyan,
                Color.orange,
                Color.brandMarkViolet,
                Color.brandMarkPurple,
            ]
            .randomElement(using: &rng) ?? Color.clear
        
        let (a, b, c) = Color.brandColorTrios.randomElement(using: &rng) ?? (Color.clear, Color.clear, Color.clear)
        
        self.gradient =  Color.brandGradient(a: a, b: b, c: c)
        
        self.blendMode =
            [
                BlendMode.colorDodge,
                BlendMode.colorBurn,
            ]
            .randomElement(using: &rng) ?? BlendMode.normal
    }
}

struct GenerativeProfilePic: View {
    var did: Did
    var size: CGFloat = 48
    
    @Environment(\.colorScheme) var colorScheme
    
       
    var body: some View {
        let params = GenerativeProfilePicParams(did: did)
        
        ZStack(alignment: .center) {
            Circle()
                .foregroundStyle(
                    .radialGradient(
                        stops: params.gradient,
                        center: .init(x: 0.5, y: 0.25), // Calculated from brandmark
                        startRadius: 0,
                        endRadius: size * 0.75 // Calculated from brandmark
                    )
                    .shadow(
                        // Eyeballed from brandmark
                        .inner(
                            color: Color.brandInnerShadow(.dark).opacity(0.5),
                            radius: 5,
                            x: 0,
                            y: 0
                        )
                    )
                )
                .frame(
                    width: size,
                    height: size,
                    alignment: .center
                )
            
            Text(params.sigil)
                .font(.system(size: size-2, weight: .heavy))
                .frame(width: size, height: size)
                .foregroundColor(Color.brandBgSlate)
                .blendMode(.darken)
                .opacity(0.3)
                .blur(radius: 3.0)
            
            Text(params.sigil)
                .font(.system(size: size-2, weight: .heavy))
                .frame(width: size, height: size)
                .foregroundColor(params.color)
                .blendMode(params.blendMode)
                .opacity(0.9)
        }
    }
}

struct GenerativeProfilePic_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            VStack {
                GenerativeProfilePic(did: Did.dummyData(), size: 24)
                GenerativeProfilePic(did: Did.dummyData(), size: 24)
                GenerativeProfilePic(did: Did.dummyData(), size: 24)
                GenerativeProfilePic(did: Did.dummyData(), size: 24)
                GenerativeProfilePic(did: Did.dummyData(), size: 24)
                GenerativeProfilePic(did: Did.dummyData(), size: 24)
                GenerativeProfilePic(did: Did.dummyData(), size: 24)
            }
            VStack {
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
            }
            VStack {
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
            }
            VStack {
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
            }
            VStack {
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
                GenerativeProfilePic(did: Did.dummyData())
            }
        }
    }
}
