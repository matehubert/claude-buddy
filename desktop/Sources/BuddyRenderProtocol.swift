import AppKit
import SceneKit

// MARK: - Mood & Environment Types

enum BuddyMood: String, Codable, CaseIterable {
    case happy, content, bored, sad, excited, grumpy
}

enum TimeOfDay: String {
    case morning   // 5-12
    case afternoon // 12-17
    case evening   // 17-21
    case night     // 21-5
}

enum ParticleEffectType {
    case slimeTrail     // snail
    case waterRipple    // duck
    case ghostFlame     // ghost
    case catStars       // cat pet
    case confetti       // achievement
    case hearts         // pet
    case raindrops      // weather
}

enum AccessoryType: String, CaseIterable {
    case umbrella, sunglasses, scarf, wings
}

// MARK: - BuddyRenderer Protocol

protocol BuddyRenderer: AnyObject {
    var view: NSView { get }

    // Click callbacks
    var onLeftClick: (() -> Void)? { get set }
    var onRightClick: ((NSEvent) -> Void)? { get set }
    var onDoubleClick: (() -> Void)? { get set }

    // Configuration
    func configure(species: String, eye: String, hat: String, shiny: Bool)

    // Animation states
    func setBlinking(_ blinking: Bool)
    func setIdleOffset(_ offset: CGFloat)
    func setBounceOffset(_ offset: CGFloat)
    func setFacingLeft(_ left: Bool)
    func setSleeping(_ sleeping: Bool)
    func setCollapsed(_ collapsed: Bool)
    func setEyeWiden(_ widen: Bool)

    // 3D-specific (no-op in 2D)
    func setMoodExpression(_ mood: BuddyMood)
    func setTimeOfDay(_ time: TimeOfDay)
    func triggerParticleEffect(_ effect: ParticleEffectType)
    func setAccessory(_ accessory: AccessoryType, visible: Bool)

    // Rigged skeletal animation (no-op if not rigged)
    func setRiggedAnimState(_ state: RiggedAnimationType)
}

enum RiggedAnimationType { case idle, walking, running }

// Default no-op implementations for optional 3D features
extension BuddyRenderer {
    func setMoodExpression(_ mood: BuddyMood) {}
    func setTimeOfDay(_ time: TimeOfDay) {}
    func triggerParticleEffect(_ effect: ParticleEffectType) {}
    func setAccessory(_ accessory: AccessoryType, visible: Bool) {}
    func setRiggedAnimState(_ state: RiggedAnimationType) {}
}
