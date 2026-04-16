import UIKit

/// Custom UIView that renders the pseudo-3D racing game using Core Graphics.
/// Uses CADisplayLink for 60fps game loop — direct port of the Canvas 2D logic.
final class RetroRacerView: UIView {

    let gameState = GameState()
    private var displayLink: CADisplayLink?
    private var lastTime: CFTimeInterval = 0

    // Virtual canvas size (matches original 640x400)
    private let W: CGFloat = 640
    private let H: CGFloat = 400

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        isMultipleTouchEnabled = true
    }

    func startGameLoop() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        displayLink?.add(to: .main, forMode: .common)
        lastTime = CACurrentMediaTime()
    }

    func stopGameLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        let now = CACurrentMediaTime()
        var dt = now - lastTime
        lastTime = now
        if dt > 0.1 { dt = 1.0 / 60.0 } // cap

        gameState.update(dt: dt)
        setNeedsDisplay()
    }

    // MARK: - Core Graphics Rendering

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        guard gameState.phase != .menu else { return }

        let theme = gameState.currentTheme ?? ThemeCatalog.all["beach"]!

        // Scale to fit view bounds
        let scaleX = bounds.width / W
        let scaleY = bounds.height / H
        ctx.saveGState()
        ctx.scaleBy(x: scaleX, y: scaleY)

        // Screen shake
        if gameState.screenShake > 0 {
            let sx = CGFloat.random(in: -1...1) * CGFloat(gameState.screenShake)
            let sy = CGFloat.random(in: -1...1) * CGFloat(gameState.screenShake)
            ctx.translateBy(x: sx, y: sy)
        }

        // Sky gradient
        drawGradient(ctx, rect: CGRect(x: 0, y: 0, width: W, height: H * 0.44),
                     top: theme.skyTop, bottom: theme.skyBot)

        // Ground fill
        ctx.setFillColor(theme.grassA.cgColor)
        ctx.fill(CGRect(x: 0, y: H * 0.42, width: W, height: H * 0.58))

        // Project road segments
        let baseIdx = Int(gameState.position / gameState.segLen)
        var x: Double = 0
        var dx: Double = 0
        var projected: [ProjectedSegment] = []

        for i in stride(from: gameState.drawDist, through: 1, by: -1) {
            let idx = baseIdx + i
            guard idx < gameState.segments.count else { continue }
            let seg = gameState.segments[idx]
            let camZ = Double(i) * gameState.segLen - gameState.position.truncatingRemainder(dividingBy: gameState.segLen)
            guard camZ > 0 else { continue }

            let scale = gameState.cameraHeight / camZ

            projected.append(ProjectedSegment(
                idx: idx,
                screenY: H * 0.5 - CGFloat(scale * seg.y * 2),
                screenX: W / 2 + CGFloat(scale * x) * W / 2,
                width: CGFloat(scale * gameState.roadWidth),
                scale: CGFloat(scale),
                segment: seg
            ))

            x += dx
            dx += seg.curve * 0.015
        }

        // Draw road strips back-to-front
        var maxY = H
        for j in 0..<projected.count {
            let p = projected[j]
            let pN: ProjectedSegment? = j > 0 ? projected[j - 1] : nil
            guard p.screenY < maxY else { continue }

            let y1 = p.screenY
            let y2 = pN?.screenY ?? H
            guard y2 > y1, y1 <= H else { continue }

            let alt = ((p.idx >> 1) & 1) == 1
            let sh = y2 - y1 + 1

            // Grass
            ctx.setFillColor((alt ? theme.grassA : theme.grassB).cgColor)
            ctx.fill(CGRect(x: 0, y: y1, width: W, height: sh))

            if p.segment.isFork && p.segment.forkSplit > 0.05 {
                drawForkRoad(ctx, p: p, alt: alt, sh: sh, y1: y1, theme: theme)
            } else {
                drawStraightRoad(ctx, p: p, alt: alt, sh: sh, y1: y1, theme: theme)
            }
            maxY = y1
        }

        // Sprites (trees) front-to-back
        for k in stride(from: projected.count - 1, through: 0, by: -1) {
            let ps = projected[k]
            guard let sp = ps.segment.sprite, ps.screenY <= H, ps.screenY >= 0 else { continue }

            let ss = ps.scale * 3000
            let sw = max(4, ss * 0.8)
            let sht = max(8, ss * 1.6)
            let sx = ps.screenX + CGFloat(sp.offset) * ps.width / 2
            let sy = ps.screenY - sht

            // Trunk
            ctx.setFillColor(UIColor(red: 93/255, green: 64/255, blue: 55/255, alpha: 1).cgColor)
            ctx.fill(CGRect(x: sx - sw * 0.08, y: sy + sht * 0.5, width: sw * 0.16, height: sht * 0.5))

            // Canopy (triangle)
            let color = theme.trees[sp.colorIdx % theme.trees.count]
            ctx.setFillColor(color.cgColor)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: sx, y: sy))
            ctx.addLine(to: CGPoint(x: sx - sw / 2, y: sy + sht * 0.6))
            ctx.addLine(to: CGPoint(x: sx + sw / 2, y: sy + sht * 0.6))
            ctx.closePath()
            ctx.fillPath()
        }

        // Fog overlay
        if let fog = theme.fog {
            ctx.setFillColor(fog.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        }

        // Player car
        drawCar(ctx, cx: W / 2 + CGFloat(gameState.playerX) * W / 6, cy: H - 20)

        // HUD
        drawHUD(ctx)

        // Stage label
        if gameState.stageLabelTimer > 0 {
            let a = min(1, gameState.stageLabelTimer)
            ctx.setFillColor(UIColor.black.withAlphaComponent(a * 0.5).cgColor)
            ctx.fill(CGRect(x: W / 2 - 120, y: 60, width: 240, height: 36))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor(red: 1, green: 211/255, blue: 42/255, alpha: a)
            ]
            let text = ">> \(gameState.stageLabel) <<"
            let size = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: W / 2 - size.width / 2, y: 64), withAttributes: attrs)
        }

        // Fork overlay
        if gameState.phase == .fork, let next = gameState.getNextTierStages() {
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.45).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: 58))

            let bounce = CGFloat(sin(gameState.forkArrowAnim)) * 3
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier-Bold", size: 18) ?? UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor(red: 1, green: 211/255, blue: 42/255, alpha: 1)
            ]
            drawCentered("CHOOSE YOUR PATH!", at: CGPoint(x: W / 2, y: 12 + bounce), attrs: titleAttrs)

            let leftAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor(red: 112/255, green: 161/255, blue: 1, alpha: 1)
            ]
            let rightAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor(red: 1, green: 107/255, blue: 107/255, alpha: 1)
            ]
            if let leftTheme = ThemeCatalog.all[next.leftStage.theme],
               let rightTheme = ThemeCatalog.all[next.rightStage.theme] {
                drawCentered("<< \(leftTheme.label)", at: CGPoint(x: W / 2 - 140, y: 36), attrs: leftAttrs)
                drawCentered("\(rightTheme.label) >>", at: CGPoint(x: W / 2 + 140, y: 36), attrs: rightAttrs)
            }
        }

        // Finish overlay
        if gameState.phase == .finished {
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.65).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

            if gameState.timer <= 0 {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Courier-Bold", size: 36) ?? UIFont.boldSystemFont(ofSize: 36),
                    .foregroundColor: UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
                ]
                drawCentered("TIME UP!", at: CGPoint(x: W / 2, y: H / 2 - 40), attrs: attrs)
            } else {
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Courier-Bold", size: 36) ?? UIFont.boldSystemFont(ofSize: 36),
                    .foregroundColor: UIColor(red: 1, green: 211/255, blue: 42/255, alpha: 1)
                ]
                drawCentered("FINISH!", at: CGPoint(x: W / 2, y: H / 2 - 50), attrs: titleAttrs)

                let scoreAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Courier-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor.white
                ]
                drawCentered("SCORE: \(gameState.score)", at: CGPoint(x: W / 2, y: H / 2 - 10), attrs: scoreAttrs)
            }

            let hintAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier", size: 13) ?? UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor(white: 0.67, alpha: 1)
            ]
            drawCentered("TAP FOR MENU", at: CGPoint(x: W / 2, y: H / 2 + 48), attrs: hintAttrs)
        }

        ctx.restoreGState()
    }

    // MARK: - Road Drawing Helpers

    private func drawStraightRoad(_ ctx: CGContext, p: ProjectedSegment, alt: Bool, sh: CGFloat, y1: CGFloat, theme: RoadTheme) {
        // Rumble strips
        ctx.setFillColor((alt ? theme.rumbleA : theme.rumbleB).cgColor)
        ctx.fill(CGRect(x: p.screenX - p.width * 0.575, y: y1, width: p.width * 1.15, height: sh))

        // Road surface
        ctx.setFillColor((alt ? theme.roadA : theme.roadB).cgColor)
        ctx.fill(CGRect(x: p.screenX - p.width / 2, y: y1, width: p.width, height: sh))

        // Center line
        if alt {
            ctx.setFillColor(theme.line.cgColor)
            ctx.fill(CGRect(x: p.screenX - p.width * 0.01, y: y1, width: p.width * 0.02, height: sh))
        } else {
            // Lane markers
            ctx.setFillColor(theme.line.withAlphaComponent(0.4).cgColor)
            ctx.fill(CGRect(x: p.screenX - p.width * 0.255, y: y1, width: p.width * 0.01, height: sh))
            ctx.fill(CGRect(x: p.screenX + p.width * 0.245, y: y1, width: p.width * 0.01, height: sh))
        }
    }

    private func drawForkRoad(_ ctx: CGContext, p: ProjectedSegment, alt: Bool, sh: CGFloat, y1: CGFloat, theme: RoadTheme) {
        let split = CGFloat(p.segment.forkSplit)
        let gap = p.width * split * 0.6
        let fw = p.width * (1 - split * 0.3)

        // Left fork
        ctx.setFillColor((alt ? theme.rumbleA : theme.rumbleB).cgColor)
        ctx.fill(CGRect(x: p.screenX - gap - fw * 0.58, y: y1, width: fw * 1.15, height: sh))
        ctx.setFillColor((alt ? theme.roadA : theme.roadB).cgColor)
        ctx.fill(CGRect(x: p.screenX - gap - fw * 0.5, y: y1, width: fw, height: sh))
        if alt {
            ctx.setFillColor(theme.line.cgColor)
            ctx.fill(CGRect(x: p.screenX - gap - fw * 0.01, y: y1, width: fw * 0.02, height: sh))
        }

        // Right fork
        ctx.setFillColor((alt ? theme.rumbleA : theme.rumbleB).cgColor)
        ctx.fill(CGRect(x: p.screenX + gap - fw * 0.58, y: y1, width: fw * 1.15, height: sh))
        ctx.setFillColor((alt ? theme.roadA : theme.roadB).cgColor)
        ctx.fill(CGRect(x: p.screenX + gap - fw * 0.5, y: y1, width: fw, height: sh))
        if alt {
            ctx.setFillColor(theme.line.cgColor)
            ctx.fill(CGRect(x: p.screenX + gap - fw * 0.01, y: y1, width: fw * 0.02, height: sh))
        }
    }

    // MARK: - Car

    private func drawCar(_ ctx: CGContext, cx: CGFloat, cy: CGFloat) {
        // Body
        ctx.setFillColor(UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 20, y: cy - 24, width: 40, height: 20))

        // Roof
        ctx.setFillColor(UIColor(red: 192/255, green: 57/255, blue: 43/255, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 12, y: cy - 32, width: 24, height: 10))

        // Windshield
        ctx.setFillColor(UIColor(red: 116/255, green: 185/255, blue: 1, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 10, y: cy - 31, width: 20, height: 7))

        // Wheels
        ctx.setFillColor(UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 22, y: cy - 22, width: 6, height: 8))
        ctx.fill(CGRect(x: cx + 16, y: cy - 22, width: 6, height: 8))
        ctx.fill(CGRect(x: cx - 22, y: cy - 8, width: 6, height: 8))
        ctx.fill(CGRect(x: cx + 16, y: cy - 8, width: 6, height: 8))

        // Tail lights
        ctx.setFillColor(UIColor(red: 1, green: 68/255, blue: 68/255, alpha: 1).cgColor)
        ctx.fill(CGRect(x: cx - 18, y: cy - 5, width: 4, height: 3))
        ctx.fill(CGRect(x: cx + 14, y: cy - 5, width: 4, height: 3))

        // Headlights for neon themes
        if let label = gameState.currentTheme?.label,
           label.contains("NEON") || label.contains("SYNTH") || label.contains("CYBER") ||
           label.contains("ARCADE") || label.contains("VAPOR") {
            ctx.setFillColor(UIColor(red: 1, green: 1, blue: 100/255, alpha: 0.5).cgColor)
            ctx.fill(CGRect(x: cx - 16, y: cy - 26, width: 4, height: 3))
            ctx.fill(CGRect(x: cx + 12, y: cy - 26, width: 4, height: 3))
        }
    }

    // MARK: - HUD

    private func drawHUD(_ ctx: CGContext) {
        let spd = Int(gameState.speed / gameState.maxSpeed * 280)
        let speedRatio = gameState.speed / gameState.maxSpeed

        // Speed bar background
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        ctx.fill(CGRect(x: 8, y: 8, width: 150, height: 16))

        // Speed bar fill
        let barColor = speedRatio > 0.8
            ? UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
            : UIColor(red: 46/255, green: 213/255, blue: 115/255, alpha: 1)
        ctx.setFillColor(barColor.cgColor)
        ctx.fill(CGRect(x: 10, y: 10, width: CGFloat(spd) / 280 * 146, height: 12))

        // Speed text
        let spdAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Courier-Bold", size: 11) ?? UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.white
        ]
        "\(spd) KMH".draw(at: CGPoint(x: 14, y: 9), withAttributes: spdAttrs)

        // Timer
        let timerColor = gameState.timer < 10
            ? UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
            : UIColor(red: 1, green: 211/255, blue: 42/255, alpha: 1)
        let timerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Courier-Bold", size: 28) ?? UIFont.boldSystemFont(ofSize: 28),
            .foregroundColor: timerColor
        ]
        drawCentered("\(Int(ceil(gameState.timer)))", at: CGPoint(x: W / 2, y: 6), attrs: timerAttrs)

        // Stage info
        let def = TrackCatalog.all[gameState.trackIdx]
        let stageAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Courier-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.white
        ]
        "STAGE \(gameState.currentTier + 1)/\(def.tiers.count)".draw(
            at: CGPoint(x: W - 130, y: 10), withAttributes: stageAttrs
        )

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Courier", size: 11) ?? UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ]
        def.name.draw(at: CGPoint(x: W - 130, y: 28), withAttributes: nameAttrs)
    }

    // MARK: - Drawing Utilities

    private func drawGradient(_ ctx: CGContext, rect: CGRect, top: UIColor, bottom: UIColor) {
        let colors = [top.cgColor, bottom.cgColor] as CFArray
        let space = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else { return }
        ctx.saveGState()
        ctx.clip(to: rect)
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: rect.midX, y: rect.minY),
                               end: CGPoint(x: rect.midX, y: rect.maxY),
                               options: [])
        ctx.restoreGState()
    }

    private func drawCentered(_ text: String, at point: CGPoint, attrs: [NSAttributedString.Key: Any]) {
        let size = text.size(withAttributes: attrs)
        text.draw(at: CGPoint(x: point.x - size.width / 2, y: point.y), withAttributes: attrs)
    }

    // MARK: - Touch Input (replaces keyboard)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)

        // Tap to go back to menu from finish screen
        if gameState.phase == .finished {
            gameState.showMenu()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameState.input = TouchInput() // reset all
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameState.input = TouchInput()
    }

    /// Map touch position to controls:
    /// Left third = steer left, Right third = steer right
    /// Top half = accelerate, Bottom half = brake
    private func handleTouches(_ touches: Set<UITouch>) {
        var input = TouchInput()
        for touch in touches {
            let loc = touch.location(in: self)
            let relX = loc.x / bounds.width
            let relY = loc.y / bounds.height

            if relX < 0.33 { input.steerLeft = true }
            if relX > 0.67 { input.steerRight = true }
            if relY < 0.5  { input.accelerate = true }
            if relY > 0.7  { input.brake = true }
        }
        gameState.input = input
    }
}
