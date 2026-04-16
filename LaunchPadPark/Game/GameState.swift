import Foundation

// MARK: - Game State Enum

enum GamePhase {
    case menu
    case playing
    case fork
    case finished
}

// MARK: - Touch Input

struct TouchInput {
    var steerLeft = false
    var steerRight = false
    var accelerate = false
    var brake = false
}

// MARK: - Game State

final class GameState: ObservableObject {
    // Constants
    let maxSpeed: Double = 300
    let segLen: Double = 200
    let cameraHeight: Double = 1000
    let drawDist: Int = 200
    let roadWidth: Double = 2000

    // Derived constants
    var accel: Double { maxSpeed / 1.5 }
    var braking: Double { maxSpeed * 1.5 }
    var decel: Double { maxSpeed * 0.6 }
    var offRoadDecel: Double { maxSpeed * 2.5 }
    var offRoadMax: Double { maxSpeed / 3 }
    let steerSpeed: Double = 3.0
    let centrifugal: Double = 0.4

    // Published state
    @Published var phase: GamePhase = .menu
    @Published var trackIdx: Int = 0
    @Published var currentTier: Int = 0
    @Published var currentStageIdx: Int = 0
    @Published var stagePath: [Int] = []
    @Published var stageLabel: String = ""
    @Published var stageLabelTimer: Double = 0

    // Game variables
    var playerX: Double = 0
    var speed: Double = 0
    var position: Double = 0
    var timer: Double = 0
    var score: Int = 0
    var screenShake: Double = 0
    var forkArrowAnim: Double = 0

    // Road
    var segments: [RoadSegment] = []
    var currentTheme: RoadTheme?

    // Input
    var input = TouchInput()

    // Audio
    private let audio = AudioEngine.shared

    // MARK: - Build Road

    func buildStageRoad(_ stageDef: StageDef) {
        guard let theme = ThemeCatalog.all[stageDef.theme] else { return }
        currentTheme = theme
        segments = []
        let len = stageDef.length
        let forkStart = len - 25

        for i in 0..<len {
            var curve: Double = 0
            var hill: Double = 0

            for cv in stageDef.curves {
                if i >= cv.start && i < cv.end {
                    let progress = Double(i - cv.start) / Double(cv.end - cv.start)
                    curve = cv.value * sin(progress * .pi)
                }
            }
            for hv in stageDef.hills {
                if i >= hv.start && i < hv.end {
                    let progress = Double(i - hv.start) / Double(hv.end - hv.start)
                    hill = hv.value * sin(progress * .pi)
                }
            }

            var sprite: SpriteInfo? = nil
            if i > 3 && i % 6 == 0 {
                let side: Double = (i % 12 == 0) ? -1 : 1
                sprite = SpriteInfo(
                    offset: side * (1.1 + Double.random(in: 0...0.5)),
                    colorIdx: i % theme.trees.count
                )
            }

            let isFork = i >= forkStart
            let forkSplit = isFork ? Double(i - forkStart) / 25.0 : 0

            segments.append(RoadSegment(
                curve: curve, y: hill,
                sprite: sprite,
                isFork: isFork, forkSplit: forkSplit
            ))
        }
    }

    // MARK: - Next Tier

    func getNextTierStages() -> (leftIdx: Int, leftStage: StageDef, rightIdx: Int, rightStage: StageDef)? {
        let def = TrackCatalog.all[trackIdx]
        let nextTier = currentTier + 1
        guard nextTier < def.tiers.count else { return nil }
        let tier = def.tiers[nextTier]
        let leftIdx = (currentStageIdx * 2) % tier.count
        let rightIdx = (currentStageIdx * 2 + 1) % tier.count
        return (leftIdx, tier[leftIdx], rightIdx, tier[rightIdx])
    }

    // MARK: - Start Game

    func startGame(trackIndex: Int) {
        trackIdx = trackIndex
        let def = TrackCatalog.all[trackIndex]
        currentTier = 0
        currentStageIdx = 0
        stagePath = [0]
        playerX = 0
        speed = 0
        position = 0
        timer = def.timeLimit
        score = 0
        screenShake = 0

        buildStageRoad(def.tiers[0][0])
        if let theme = ThemeCatalog.all[def.tiers[0][0].theme] {
            stageLabel = theme.label
        }
        stageLabelTimer = 3
        phase = .playing

        audio.startEngineSound()
    }

    // MARK: - Advance Stage

    func advanceToNextStage(chosenIdx: Int) {
        let def = TrackCatalog.all[trackIdx]
        currentTier += 1

        if currentTier >= def.tiers.count {
            phase = .finished
            score = Int(timer * 1000)
            audio.stopEngineSound()
            audio.playFinishSound()
            return
        }

        currentStageIdx = chosenIdx
        stagePath.append(chosenIdx)
        let stage = def.tiers[currentTier][chosenIdx]
        buildStageRoad(stage)
        position = 0

        if let theme = ThemeCatalog.all[stage.theme] {
            stageLabel = theme.label
        }
        stageLabelTimer = 3
        timer += 12
        audio.playStageSound()
        phase = .playing
    }

    // MARK: - Return to Menu

    func showMenu() {
        phase = .menu
        audio.stopEngineSound()
    }

    // MARK: - Update (called each frame)

    func update(dt: Double) {
        guard phase == .playing || phase == .fork else { return }

        forkArrowAnim += dt * 4
        if stageLabelTimer > 0 { stageLabelTimer -= dt }

        timer -= dt
        if timer <= 0 {
            timer = 0
            phase = .finished
            audio.stopEngineSound()
            audio.playFinishSound()
            return
        }

        // Fork state: slow down, wait for choice
        if phase == .fork {
            speed -= decel * 2 * dt
            if speed < 0 { speed = 0 }

            if input.steerLeft, let next = getNextTierStages() {
                audio.playForkSound()
                advanceToNextStage(chosenIdx: next.leftIdx)
            }
            if input.steerRight, let next = getNextTierStages() {
                audio.playForkSound()
                advanceToNextStage(chosenIdx: next.rightIdx)
            }
            audio.updateEngineSound(speedRatio: speed / maxSpeed)
            return
        }

        // Acceleration / braking
        if input.accelerate {
            speed += accel * dt
        } else if input.brake {
            speed -= braking * dt
        } else {
            speed -= decel * dt
        }

        // Off-road penalty
        if abs(playerX) > 1.0 {
            speed -= offRoadDecel * dt
            if speed > offRoadMax { speed = offRoadMax }
            screenShake = 3
        } else {
            if screenShake > 0 { screenShake -= dt * 20 }
            if screenShake < 0 { screenShake = 0 }
        }

        speed = max(0, min(speed, maxSpeed))

        // Steering
        let speedRatio = speed / maxSpeed
        if input.steerLeft  { playerX -= steerSpeed * dt * speedRatio }
        if input.steerRight { playerX += steerSpeed * dt * speedRatio }

        // Centrifugal force
        let segIdx = Int(position / segLen) % max(1, segments.count)
        if segIdx < segments.count {
            playerX += segments[segIdx].curve * centrifugal * dt * speedRatio
        }
        playerX = max(-2.5, min(2.5, playerX))

        // Move forward
        position += speed * dt

        // Check stage end
        let stageLen = Double(segments.count) * segLen
        if position >= stageLen {
            position = stageLen - 1
            speed = max(speed * 0.5, 0)

            if getNextTierStages() != nil {
                phase = .fork
            } else {
                phase = .finished
                score = Int(timer * 1000)
                audio.stopEngineSound()
                audio.playFinishSound()
            }
        }

        audio.updateEngineSound(speedRatio: speedRatio)
    }
}
