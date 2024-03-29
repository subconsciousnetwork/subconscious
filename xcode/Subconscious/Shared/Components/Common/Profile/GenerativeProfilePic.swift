//
//  GenerativeProfilePic.swift
//  Subconscious
//
//  Created by Ben Follington on 25/4/2023.
//

import SwiftUI
import GameplayKit

struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
    private let randomSource: GKARC4RandomSource

    init(seed: String) {
        let data = Data(seed.utf8)
        self.randomSource = GKARC4RandomSource(seed: data)
        
        // To improve the quality of the random numbers, it's recommended to drop the first N values
        randomSource.dropValues(1024)
    }

    mutating func next() -> UInt64 {
        // nextInt() generates a random number between 0 and Int32.max inclusive.
        // Carefully combine these into 64 bits of randomness.
        let highBits = UInt64(randomSource.nextInt(upperBound: Int(UInt32.max)))
        let lowBits = UInt64(randomSource.nextInt(upperBound: Int(UInt32.max)))
        return highBits << 32 | lowBits
    }
}

struct GenerativeProfilePicParams {
    var sigil: String
    var blendMode: BlendMode
    var color: Color
    var gradient: [Gradient.Stop]
    
    private static let gradientOptions = [
        (Color.brandMarkPink, Color.brandMarkViolet, Color.brandMarkCyan),
        (Color.brandMarkRed, Color.brandMarkPurple, Color.brandMarkViolet),
        (Color.brandBgBlush, Color.brandMarkPurple, Color.brandMarkCyan),
        (Color.brandMarkRed, Color.brandMarkViolet, Color.brandMarkCyan),
        (Color.brandMarkRed, Color.brandMarkPurple, Color.brandMarkPink),
        (Color.yellow, Color.orange, Color.brandMarkRed),
        (Color.brandMarkPink, Color(red: 0.25, green: 0.478, blue: 1, opacity: 1), Color.brandMarkRed),
        (Color.white, Color.brandBgBlush, Color.brandMarkPink),
        (Color.brandMarkPink, Color(red: 0.25, green: 0.478, blue: 1, opacity: 1), Color.brandMarkCyan),
        (Color.brandMarkCyan, Color(red: 0.25, green: 0.478, blue: 1, opacity: 1), Color.orange)
    ]
    
    private static let sigilOptions = [
        "✶",
        "✴︎",
        "✸",
        "✺",
        "✦",
        "✷",
        "☾",
        "♦︎"
    ]
    
    private static let colorOptions = [
        Color.blue,
        Color.gray,
        Color.cyan,
        Color.brandMarkViolet,
        Color.brandMarkPurple
    ]
    
    private static let blendModeOptions = [
        BlendMode.colorDodge,
        BlendMode.colorBurn
    ]
}

extension GenerativeProfilePicParams {
    init(did: Did) {
        var rng = RandomNumberGeneratorWithSeed(seed: did.did)
        
        self.sigil =
            Self.sigilOptions.randomElement(using: &rng)
                ?? ""
        
        self.color =
            Self.colorOptions.randomElement(using: &rng)
                ?? Color.clear
        
        let (a, b, c) =
            Self.gradientOptions.randomElement(using: &rng)
                ?? (Color.clear, Color.clear, Color.clear)
        
        self.gradient = Color.brandGradient(a: a, b: b, c: c)
        
        self.blendMode =
            Self.blendModeOptions.randomElement(using: &rng)
                ?? BlendMode.normal
    }
}

struct GenerativeProfilePic: View {
    var did: Did
    var size: CGFloat = AppTheme.lgPfpSize
    
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
                            color: Color.brandInnerShadow(.light).opacity(0.5),
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
                .font(.system(size: size * 0.8, weight: .heavy))
                .frame(width: size, height: size)
                .foregroundColor(Color.brandBgSlate)
                .blendMode(.darken)
                .opacity(0.3)
                .blur(radius: 3.0)
            
            Text(params.sigil)
                .font(.system(size: size * 0.8, weight: .heavy))
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
