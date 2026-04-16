import UIKit

// MARK: - Road Theme

struct RoadTheme {
    let skyTop: UIColor
    let skyBot: UIColor
    let grassA: UIColor
    let grassB: UIColor
    let roadA: UIColor
    let roadB: UIColor
    let rumbleA: UIColor
    let rumbleB: UIColor
    let line: UIColor
    let trees: [UIColor]
    let fog: UIColor?
    let label: String
}

// MARK: - Stage Definition

struct StageCurve {
    let start: Int
    let end: Int
    let value: Double
}

struct StageDef {
    let theme: String
    let length: Int
    let curves: [StageCurve]
    let hills: [StageCurve]
}

// MARK: - Track Definition

struct TrackDef {
    let name: String
    let timeLimit: Double
    let tiers: [[StageDef]]  // tiers[tierIndex][stageIndex]
}

// MARK: - Road Segment

struct RoadSegment {
    var curve: Double
    var y: Double
    var sprite: SpriteInfo?
    var isFork: Bool
    var forkSplit: Double
}

struct SpriteInfo {
    let offset: Double
    let colorIdx: Int
}

// MARK: - Projected Segment (for rendering)

struct ProjectedSegment {
    let idx: Int
    let screenY: CGFloat
    let screenX: CGFloat
    let width: CGFloat
    let scale: CGFloat
    let segment: RoadSegment
}

// MARK: - Theme Catalog

enum ThemeCatalog {
    static func color(_ hex: String) -> UIColor {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        return UIColor(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }

    static let all: [String: RoadTheme] = [
        "beach": RoadTheme(
            skyTop: color("#1e90ff"), skyBot: color("#87ceeb"),
            grassA: color("#2ed573"), grassB: color("#26c665"),
            roadA: color("#555555"), roadB: color("#666666"),
            rumbleA: color("#e74c3c"), rumbleB: color("#ffffff"),
            line: color("#ffffff"),
            trees: [color("#0b5345"), color("#117a65"), color("#1abc9c")],
            fog: nil, label: "BEACH"
        ),
        "cliff": RoadTheme(
            skyTop: color("#4a90d9"), skyBot: color("#a0c4e8"),
            grassA: color("#556b2f"), grassB: color("#6b8e23"),
            roadA: color("#666666"), roadB: color("#777777"),
            rumbleA: color("#ffffff"), rumbleB: color("#e74c3c"),
            line: color("#ffffff"),
            trees: [color("#556b2f"), color("#228b22"), color("#3cb371")],
            fog: nil, label: "CLIFFSIDE"
        ),
        "harbor": RoadTheme(
            skyTop: color("#2980b9"), skyBot: color("#85c1e9"),
            grassA: color("#1a8a5c"), grassB: color("#1e9e6a"),
            roadA: color("#505050"), roadB: color("#606060"),
            rumbleA: color("#3498db"), rumbleB: color("#ffffff"),
            line: color("#ecf0f1"),
            trees: [color("#0e6655"), color("#148f77"), color("#1abc9c")],
            fog: nil, label: "HARBOR"
        ),
        "jungle": RoadTheme(
            skyTop: color("#0e6251"), skyBot: color("#27ae60"),
            grassA: color("#145a32"), grassB: color("#196f3d"),
            roadA: color("#4a3728"), roadB: color("#5a4738"),
            rumbleA: color("#f39c12"), rumbleB: color("#27ae60"),
            line: color("#f1c40f"),
            trees: [color("#0b3d0b"), color("#145a32"), color("#1e8449")],
            fog: UIColor(red: 0, green: 80/255, blue: 40/255, alpha: 0.08), label: "JUNGLE"
        ),
        "sunset": RoadTheme(
            skyTop: color("#e74c3c"), skyBot: color("#f39c12"),
            grassA: color("#2ecc71"), grassB: color("#27ae60"),
            roadA: color("#555555"), roadB: color("#666666"),
            rumbleA: color("#e74c3c"), rumbleB: color("#ffd32a"),
            line: color("#ffffff"),
            trees: [color("#0b5345"), color("#117a65"), color("#d35400")],
            fog: nil, label: "SUNSET COAST"
        ),
        "dunes": RoadTheme(
            skyTop: color("#ff7f50"), skyBot: color("#ffeaa7"),
            grassA: color("#daa520"), grassB: color("#cd950c"),
            roadA: color("#8B7355"), roadB: color("#9C8565"),
            rumbleA: color("#e74c3c"), rumbleB: color("#ffd32a"),
            line: color("#ffd32a"),
            trees: [color("#8B4513"), color("#A0522D"), color("#D2691E")],
            fog: UIColor(red: 1, green: 200/255, blue: 100/255, alpha: 0.12), label: "DUNES"
        ),
        "canyon": RoadTheme(
            skyTop: color("#e67e22"), skyBot: color("#f5cba7"),
            grassA: color("#a0522d"), grassB: color("#8b4513"),
            roadA: color("#6b4226"), roadB: color("#7b5236"),
            rumbleA: color("#c0392b"), rumbleB: color("#f39c12"),
            line: color("#f1c40f"),
            trees: [color("#6b3a2a"), color("#8b5e3c"), color("#a0522d")],
            fog: nil, label: "CANYON"
        ),
        "oasis": RoadTheme(
            skyTop: color("#2980b9"), skyBot: color("#a9dfbf"),
            grassA: color("#52be80"), grassB: color("#45b76e"),
            roadA: color("#7b6b55"), roadB: color("#8b7b65"),
            rumbleA: color("#1abc9c"), rumbleB: color("#ffffff"),
            line: color("#ffffff"),
            trees: [color("#1e8449"), color("#27ae60"), color("#2ecc71")],
            fog: nil, label: "OASIS"
        ),
        "mesa": RoadTheme(
            skyTop: color("#dc7633"), skyBot: color("#fad7a0"),
            grassA: color("#b7950b"), grassB: color("#a68307"),
            roadA: color("#7e6b55"), roadB: color("#8e7b65"),
            rumbleA: color("#e74c3c"), rumbleB: color("#f5b041"),
            line: color("#ffd32a"),
            trees: [color("#784212"), color("#935116"), color("#a04000")],
            fog: UIColor(red: 200/255, green: 150/255, blue: 50/255, alpha: 0.1), label: "MESA"
        ),
        "mirage": RoadTheme(
            skyTop: color("#f0b27a"), skyBot: color("#fdebd0"),
            grassA: color("#d4ac0d"), grassB: color("#c4a00d"),
            roadA: color("#9b8b75"), roadB: color("#ab9b85"),
            rumbleA: color("#e74c3c"), rumbleB: color("#ffffff"),
            line: color("#ecf0f1"),
            trees: [color("#b7950b"), color("#d4ac0d"), color("#f1c40f")],
            fog: UIColor(red: 1, green: 230/255, blue: 180/255, alpha: 0.15), label: "MIRAGE"
        ),
        "neonCity": RoadTheme(
            skyTop: color("#0a0a2e"), skyBot: color("#1a1a4e"),
            grassA: color("#0d0d30"), grassB: color("#0a0a25"),
            roadA: color("#1a1a3e"), roadB: color("#22224e"),
            rumbleA: color("#ff00ff"), rumbleB: color("#00ffff"),
            line: color("#00ffff"),
            trees: [color("#ff00ff"), color("#00ffff"), color("#ff6b6b")],
            fog: nil, label: "NEON CITY"
        ),
        "synthwave": RoadTheme(
            skyTop: color("#1a0533"), skyBot: color("#2d1b69"),
            grassA: color("#110022"), grassB: color("#0d001a"),
            roadA: color("#1a1040"), roadB: color("#221850"),
            rumbleA: color("#ff1493"), rumbleB: color("#00ff7f"),
            line: color("#ff1493"),
            trees: [color("#ff1493"), color("#00ff7f"), color("#ffff00")],
            fog: nil, label: "SYNTHWAVE"
        ),
        "cyberpunk": RoadTheme(
            skyTop: color("#0d0d0d"), skyBot: color("#1a1a2e"),
            grassA: color("#0a0a0a"), grassB: color("#111118"),
            roadA: color("#222230"), roadB: color("#2a2a40"),
            rumbleA: color("#ff4500"), rumbleB: color("#00bfff"),
            line: color("#ff4500"),
            trees: [color("#ff4500"), color("#00bfff"), color("#39ff14")],
            fog: nil, label: "CYBERPUNK"
        ),
        "arcade": RoadTheme(
            skyTop: color("#0f0030"), skyBot: color("#1a004e"),
            grassA: color("#0a0020"), grassB: color("#0d0028"),
            roadA: color("#18183e"), roadB: color("#20204e"),
            rumbleA: color("#ffff00"), rumbleB: color("#ff00ff"),
            line: color("#ffff00"),
            trees: [color("#ffff00"), color("#ff00ff"), color("#00ffff")],
            fog: nil, label: "ARCADE ZONE"
        ),
        "vaporwave": RoadTheme(
            skyTop: color("#2b0040"), skyBot: color("#400060"),
            grassA: color("#15002a"), grassB: color("#1a0033"),
            roadA: color("#25104a"), roadB: color("#30185a"),
            rumbleA: color("#ff69b4"), rumbleB: color("#40e0d0"),
            line: color("#ff69b4"),
            trees: [color("#ff69b4"), color("#40e0d0"), color("#dda0dd")],
            fog: UIColor(red: 100/255, green: 0, blue: 150/255, alpha: 0.06), label: "VAPORWAVE"
        )
    ]
}

// MARK: - Helper to build StageDef

private func S(_ theme: String, _ length: Int, _ curves: [(Int, Int, Double)], _ hills: [(Int, Int, Double)]) -> StageDef {
    StageDef(
        theme: theme, length: length,
        curves: curves.map { StageCurve(start: $0.0, end: $0.1, value: $0.2) },
        hills: hills.map { StageCurve(start: $0.0, end: $0.1, value: $0.2) }
    )
}

// MARK: - Track Definitions

enum TrackCatalog {
    static let all: [TrackDef] = [
        // COASTAL CRUISE
        TrackDef(name: "COASTAL CRUISE", timeLimit: 90, tiers: [
            [S("beach", 120, [(10,35,4),(50,80,-5),(90,115,6)], [(15,45,25),(60,90,-20),(100,115,15)])],
            [S("cliff", 100, [(5,25,-7),(30,55,8),(60,85,-9),(88,98,6)], [(10,40,40),(50,75,-35),(80,95,30)]),
             S("harbor", 100, [(5,30,5),(35,60,-6),(65,95,7)], [(8,30,20),(40,65,-15),(75,95,25)])],
            [S("jungle", 100, [(5,18,9),(22,40,-10),(45,65,8),(70,90,-9)], [(10,35,45),(45,70,-40),(80,95,35)]),
             S("sunset", 100, [(5,28,-6),(35,60,7),(68,95,-8)], [(10,40,30),(55,80,-25)]),
             S("beach", 100, [(8,28,7),(35,55,-8),(60,80,10),(85,95,-7)], [(5,30,35),(40,65,-30),(75,95,25)]),
             S("cliff", 100, [(5,25,-8),(30,50,9),(55,80,-10),(85,95,8)], [(10,35,40),(50,75,-35)])],
            [S("sunset", 80, [(2,12,10),(15,28,-12),(32,48,11),(52,65,-10),(68,78,8)], [(5,25,35),(30,55,-30),(60,78,25)]),
             S("jungle", 80, [(3,16,-11),(20,35,12),(40,55,-10),(60,75,9)], [(5,30,40),(40,60,-35)]),
             S("harbor", 80, [(2,15,9),(18,32,-11),(36,52,10),(56,72,-8)], [(8,30,30),(38,58,-25)]),
             S("beach", 80, [(5,18,-10),(22,38,12),(42,58,-11),(62,78,9)], [(5,25,35),(35,55,-30)]),
             S("cliff", 80, [(3,15,11),(18,32,-13),(36,52,10),(56,72,-9)], [(5,28,45),(38,58,-40),(65,78,30)]),
             S("sunset", 80, [(2,15,-12),(18,35,11),(40,58,-10),(62,78,8)], [(8,28,35),(38,58,-30)]),
             S("jungle", 80, [(2,12,10),(16,30,-12),(35,50,11),(55,70,-9)], [(5,25,40),(35,55,-35)]),
             S("harbor", 80, [(3,16,-9),(20,36,10),(40,56,-11),(60,78,8)], [(5,25,30),(35,55,-25)])]
        ]),

        // DESERT STORM
        TrackDef(name: "DESERT STORM", timeLimit: 85, tiers: [
            [S("dunes", 120, [(10,40,-5),(50,80,7),(90,115,-6)], [(15,50,40),(60,90,-35),(100,115,25)])],
            [S("canyon", 100, [(5,20,8),(25,45,-10),(50,70,9),(75,95,-8)], [(10,35,45),(45,70,-40),(80,95,30)]),
             S("oasis", 100, [(5,30,-5),(40,65,6),(70,95,-7)], [(10,35,25),(45,70,-20)])],
            [S("mesa", 100, [(5,18,10),(22,40,-12),(45,65,11),(70,90,-10)], [(10,40,50),(50,80,-45)]),
             S("mirage", 100, [(5,25,-7),(30,55,8),(60,85,-9)], [(10,35,30),(50,75,-25)]),
             S("dunes", 100, [(5,28,8),(35,58,-9),(62,85,10)], [(10,35,35),(50,75,-30)]),
             S("canyon", 100, [(5,22,-9),(28,50,11),(55,78,-10),(82,95,9)], [(10,40,45),(50,80,-40)])],
            [S("oasis", 80, [(2,15,12),(18,32,-13),(35,50,11),(55,70,-10),(73,78,8)], [(5,25,40),(35,55,-35),(60,78,30)]),
             S("mesa", 80, [(3,16,-11),(20,35,13),(40,55,-12),(60,78,10)], [(5,30,45),(40,60,-40)]),
             S("canyon", 80, [(2,15,10),(18,32,-12),(36,52,11),(56,72,-9)], [(8,30,35),(38,58,-30)]),
             S("mirage", 80, [(5,18,-10),(22,38,11),(42,58,-12),(62,78,8)], [(5,25,30),(35,55,-25)]),
             S("dunes", 80, [(3,14,11),(18,32,-13),(36,50,10),(55,70,-9)], [(5,28,40),(38,58,-35)]),
             S("oasis", 80, [(5,16,-12),(20,36,11),(42,58,-10),(62,78,9)], [(8,28,35),(38,58,-30)]),
             S("mesa", 80, [(2,14,10),(18,32,-11),(36,52,12),(56,72,-8)], [(5,25,35),(35,55,-30)]),
             S("canyon", 80, [(3,16,-10),(20,36,12),(40,56,-11),(60,78,9)], [(5,25,40),(35,55,-35)])]
        ]),

        // NEON NIGHTS
        TrackDef(name: "NEON NIGHTS", timeLimit: 80, tiers: [
            [S("neonCity", 120, [(10,35,5),(45,75,-7),(85,115,6)], [(15,45,20),(55,85,-25),(95,115,18)])],
            [S("synthwave", 100, [(5,22,-8),(28,50,10),(55,75,-9),(80,95,8)], [(10,35,35),(45,70,-30),(80,95,25)]),
             S("cyberpunk", 100, [(5,25,6),(30,55,-8),(60,85,7),(88,98,-6)], [(10,30,25),(40,65,-20)])],
            [S("arcade", 100, [(5,18,11),(22,40,-13),(45,60,12),(65,82,-11)], [(10,38,40),(48,75,-35)]),
             S("vaporwave", 100, [(5,28,-7),(35,58,9),(65,88,-8)], [(10,35,30),(50,75,-25)]),
             S("neonCity", 100, [(5,25,8),(30,50,-10),(55,78,9),(82,95,-8)], [(8,32,32),(42,68,-28)]),
             S("synthwave", 100, [(5,22,-9),(28,48,11),(55,78,-10),(82,95,8)], [(10,35,38),(50,75,-32)])],
            [S("cyberpunk", 80, [(2,12,12),(15,28,-14),(32,48,13),(52,65,-12),(68,78,10)], [(5,25,40),(35,55,-35),(60,78,30)]),
             S("arcade", 80, [(3,16,-13),(20,35,14),(40,55,-12),(60,78,11)], [(5,28,38),(38,58,-32)]),
             S("vaporwave", 80, [(2,14,11),(18,32,-13),(36,52,12),(56,72,-10)], [(5,25,35),(35,55,-30)]),
             S("neonCity", 80, [(3,16,-12),(20,36,13),(40,56,-11),(60,78,10)], [(5,30,42),(40,60,-38)]),
             S("synthwave", 80, [(2,12,13),(16,30,-14),(34,48,12),(52,68,-11),(72,78,9)], [(5,25,38),(35,55,-32)]),
             S("cyberpunk", 80, [(3,14,-11),(18,34,13),(38,54,-12),(58,78,10)], [(5,28,35),(38,58,-30)]),
             S("arcade", 80, [(2,14,12),(18,32,-13),(36,52,11),(56,72,-10)], [(5,25,40),(35,55,-35)]),
             S("vaporwave", 80, [(3,16,-12),(20,36,14),(40,56,-13),(60,78,10)], [(5,28,38),(38,58,-32)])]
        ])
    ]
}
