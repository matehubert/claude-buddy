import Foundation

// MARK: - Buddy Localization

/// Lightweight localization for buddy reaction strings.
/// Supported languages: "en", "hu". Falls back to "en" for unknown codes.
enum BuddyL10n {
    /// Current language code. Set on launch from BuddySoul.language or auto-detected.
    static var current: String = "en"

    /// Detect language from system locale. Returns "hu" if Hungarian, otherwise "en".
    static func detectSystemLanguage() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return supportedLanguages.contains(code) ? code : "en"
    }

    /// Initialize language from soul or auto-detect. Call once on launch.
    static func setup(soul: BuddySoul?) {
        if let lang = soul?.language, supportedLanguages.contains(lang) {
            current = lang
        } else {
            current = detectSystemLanguage()
        }
    }

    static let supportedLanguages = ["en", "hu"]

    // MARK: - Mood Texts

    static var moodHappy: [String] {
        current == "hu"
            ? ["Jól érzem magam!", "Boldog vagyok!", ":D"]
            : ["Feeling great!", "Happy!", ":D"]
    }

    static var moodContent: [String] {
        current == "hu"
            ? ["Minden oké~", "Elégedett.", "Jól vagyok."]
            : ["Feeling okay~", "Content.", "All good."]
    }

    static var moodBored: [String] {
        current == "hu"
            ? ["Unatkozom...", "*ásít*", "..."]
            : ["Bored...", "*yawn*", "..."]
    }

    static var moodSad: [String] {
        current == "hu"
            ? ["Szomorú vagyok...", ":(", "Hiányzol..."]
            : ["Feeling down...", ":(", "Miss you..."]
    }

    static var moodExcited: [String] {
        current == "hu"
            ? ["NAGYON IZGATOTT!", "!!!", "Juhú!!!"]
            : ["SO EXCITED!", "!!!", "Yay!!!"]
    }

    static var moodGrumpy: [String] {
        current == "hu"
            ? ["Hmph.", "grr.", ">:("]
            : ["Hmph.", "grr.", ">:("]
    }

    // MARK: - Pet Defaults

    static var petDefaults: [String] {
        current == "hu"
            ? ["♥", "Dorr~", ":3", "juhú!", "^_^"]
            : ["♥", "Purr~", ":3", "yay!", "^_^"]
    }

    // MARK: - Feed

    static var feedReaction: String {
        current == "hu" ? "*nyam nyam nyam* Köszi!" : "*nom nom nom* Thanks!"
    }

    // MARK: - Pomodoro

    static var pomodoroFocusPrefix: String {
        current == "hu" ? "Fókusz" : "Focus"
    }

    static var pomodoroBreakPrefix: String {
        current == "hu" ? "Szünet" : "Break"
    }

    static var pomodoroWork: String {
        current == "hu" ? "Fókusz idő! Rajta!" : "Focus time! Let's go!"
    }

    static var pomodoroShortBreak: String {
        current == "hu" ? "Szünet! Nyújtózz!" : "Break time! Stretch!"
    }

    static var pomodoroLongBreak: String {
        current == "hu" ? "Hosszú szünet! Megérdemelted!" : "Long break! You earned it!"
    }

    static var pomodoroStopped: String {
        current == "hu" ? "Pomodoro leállítva." : "Pomodoro stopped."
    }

    // MARK: - Rain / Weather

    static var itsRaining: String {
        current == "hu" ? "Esik az eső!" : "It's raining!"
    }

    // MARK: - Achievement

    static func achievementUnlocked(_ name: String) -> String {
        current == "hu" ? "Eredmény: \(name)" : "Achievement: \(name)"
    }

    // MARK: - Customize Reactions

    static var newLook: String {
        current == "hu" ? "Új kinézet!" : "New look!"
    }

    static var backToNormal: String {
        current == "hu" ? "Vissza a régihez!" : "Back to normal!"
    }

    static var niceHat: String {
        current == "hu" ? "Szép sapka!" : "Nice hat!"
    }

    static var hatRemoved: String {
        current == "hu" ? "Sapka levéve!" : "Hat removed!"
    }

    static var originalHat: String {
        current == "hu" ? "Eredeti sapka visszaállítva!" : "Original hat restored!"
    }

    static var photoRequires3D: String {
        current == "hu" ? "Fotóhoz 3D mód kell!" : "Photo requires 3D mode!"
    }

    // MARK: - Sleep / Wake

    static var wakeTexts: [String] {
        current == "hu"
            ? ["hmm..?", "*ásít~*", "*nyújtózik*", "oh!", "..hm?"]
            : ["hmm..?", "yawn~", "*stretch*", "oh!", "..huh?"]
    }

    // MARK: - Curiosity (Explore)

    static var curiosityTexts: [String] {
        current == "hu"
            ? ["hmm?", "az mi?", "..!", "érdekes~", "ooh"]
            : ["hmm?", "what's that?", "..!", "interesting~", "ooh"]
    }

    // MARK: - Species Tricks

    static var duckQuack: String { current == "hu" ? "*háp háp!*" : "*quack quack!*" }
    static var catPurr: String { current == "hu" ? "dorrrr~" : "purrrr~" }
    static var snailHides: String { current == "hu" ? "*elbújik*" : "*hides*" }
    static var snailHi: String { current == "hu" ? "...szia" : "...hi" }
    static var ghostBoo: String { "BOO!" }
    static var defaultTrick: String { current == "hu" ? "juhúú!" : "wheee!" }

    // MARK: - Shake

    static var shakeReaction: String { current == "hu" ? "Hujujuj!" : "Wheee!" }

    // MARK: - Mouse Scared

    static var mouseScared: String { "!" }

    // MARK: - Git Events

    static var gitCommit: [String] {
        current == "hu"
            ? ["Szép commit!", "Hajrá!", "Kód commitolva!", "Jó mentés!", "Commitolva!"]
            : ["Nice commit!", "Ship it!", "Code committed!", "Good save!", "Committed!"]
    }

    static var gitConflict: [String] {
        current == "hu"
            ? ["Jaj! Merge konflikt!", "Konflikt! Sok sikert!", "Ajaj, konfliktusok..."]
            : ["Yikes! Merge conflict!", "Conflict detected! Good luck!", "Uh oh, conflicts..."]
    }

    static var gitBranchSwitch: [String] {
        current == "hu"
            ? ["Új branch!", "Branch váltás!", "Másik branch!"]
            : ["New branch!", "Branch switch!", "Different branch now!"]
    }

    static var gitPush: [String] {
        current == "hu"
            ? ["Pusholva!", "A kód kint van!", "Kitelepítve!"]
            : ["Pushed!", "Code is live!", "Deployed!"]
    }

    static var gitDefault: String {
        current == "hu" ? "Git aktivitás!" : "Git activity!"
    }

    // MARK: - Clipboard Events

    static var clipboardLargePaste: [String] {
        current == "hu"
            ? ["Ez aztán a nagy paste!", "Sok kód!", "Kemény meló!"]
            : ["Heavy lifting!", "That's a big paste!", "Lots of code!"]
    }

    static var clipboardCodeCopy: [String] {
        current == "hu"
            ? ["Kódot másolsz?", "Ctrl+C elkapva!", "Kódrészlet!"]
            : ["Copying code?", "Ctrl+C detected!", "Code snippet!"]
    }

    // MARK: - Mini Games

    static var clickCatchIntro: String {
        current == "hu" ? "Kattintós! Kattints rám, ha RAJTA-t mondok!" : "Click Catch! Click me when I say GO!"
    }

    static var clickCatchWait: String {
        current == "hu" ? "Várj rá..." : "Wait for it..."
    }

    static var clickCatchGo: String {
        current == "hu" ? "RAJTA! Kattints!" : "GO! Click me!"
    }

    static var clickCatchTooSlow: String {
        current == "hu" ? "Túl lassú!" : "Too slow!"
    }

    static func clickCatchNice(_ score: Int) -> String {
        current == "hu" ? "Szép! Pont: \(score)" : "Nice! Score: \(score)"
    }

    static var hideAndSeekIntro: String {
        current == "hu" ? "Bújócska! Elbújok, keress meg!" : "Hide & Seek! I'll hide, you find me!"
    }

    static var hideAndSeekHides: String {
        current == "hu" ? "*elbújik*" : "*hides*"
    }

    static func hideAndSeekFound(_ bonus: Int, _ score: Int) -> String {
        current == "hu" ? "Megtaláltál! +\(bonus) pont (Össz: \(score))" : "Found me! +\(bonus) pts (Score: \(score))"
    }

    static var hideAndSeekTooSlow: String {
        current == "hu" ? "Túl lassú! Itt vagyok!" : "Too slow! Here I am!"
    }

    static var triviaIntro: String {
        current == "hu" ? "Kvíz idő! 3 kérdés!" : "Trivia time! 3 questions!"
    }

    static func triviaTimesUp(_ answer: String) -> String {
        current == "hu" ? "Lejárt az idő! Válasz: \(answer)" : "Time's up! Answer: \(answer)"
    }

    static func triviaCorrect(_ score: Int) -> String {
        current == "hu" ? "Helyes! Pont: \(score)" : "Correct! Score: \(score)"
    }

    static var triviaWrong: String {
        current == "hu" ? "Rossz!" : "Wrong!"
    }

    static func gameOver(_ score: Int) -> String {
        current == "hu" ? "Vége! Pont: \(score)" : "Game over! Score: \(score)"
    }

    // MARK: - Menu Strings

    static var menuHideBuddy: String { current == "hu" ? "Buddy elrejtése" : "Hide Buddy" }
    static var menuShowBuddy: String { current == "hu" ? "Buddy mutatása" : "Show Buddy" }
    static var menuPet: String { current == "hu" ? "Simogatás" : "Pet" }
    static var menuFeed: String { current == "hu" ? "Etetés" : "Feed" }
    static var menuViewCard: String { current == "hu" ? "Kártya" : "View Card" }
    static var menuUsage: String { current == "hu" ? "Használat" : "Usage" }
    static var menuPomodoro: String { "Pomodoro" }
    static var menuStop: String { current == "hu" ? "Leállítás" : "Stop" }
    static var menuStart25: String { current == "hu" ? "Indítás (25 perc)" : "Start (25 min)" }
    static var menuGames: String { current == "hu" ? "Játékok" : "Games" }
    static var menuEndGame: String { current == "hu" ? "Játék vége" : "End Game" }
    static var menuCustomize: String { current == "hu" ? "Testreszabás" : "Customize" }
    static var menuEyes: String { current == "hu" ? "Szemek" : "Eyes" }
    static var menuHat: String { current == "hu" ? "Sapka" : "Hat" }
    static var menuAccessories: String { current == "hu" ? "Kiegészítők" : "Accessories" }
    static var menuLanguage: String { current == "hu" ? "Nyelv" : "Language" }
    static var menuTakePhoto: String { current == "hu" ? "Fotó készítése" : "Take Photo" }
    static var menuMuteReactions: String { current == "hu" ? "Reakciók némítása" : "Mute Reactions" }
    static var menuUnmuteReactions: String { current == "hu" ? "Reakciók engedélyezése" : "Unmute Reactions" }
    static var menuResetDefault: String { current == "hu" ? "Alapértelmezettre" : "Reset to Default" }
    static var menuCenterBuddy: String { current == "hu" ? "Középre" : "Center Buddy" }
    static var menuReroll: String { current == "hu" ? "Új tojás kikeltetése..." : "Hatch new egg..." }
    static var menuRerollConfirm: String {
        current == "hu"
            ? "Biztos? Az aktuális buddyd elköszön, és egy teljesen új tojást kapsz nulláról."
            : "Are you sure? Your current buddy will leave, and you'll hatch a brand new egg from scratch."
    }
    static var menuRerollConfirmButton: String { current == "hu" ? "Új tojás!" : "New egg!" }
    static var menuCancel: String { current == "hu" ? "Mégse" : "Cancel" }
    static var menuQuit: String { current == "hu" ? "Kilépés" : "Quit" }

    static func menuGameInProgress(_ score: Int) -> String {
        current == "hu" ? "Játék folyamatban (Pont: \(score))" : "Game in progress (Score: \(score))"
    }

    static func menuMoodEnergy(_ mood: String, _ energy: String) -> String {
        current == "hu" ? "Hangulat: \(mood) | Energia: \(energy)" : "Mood: \(mood) | Energy: \(energy)"
    }

    // MARK: - Language display names

    static let languageNames: [String: String] = [
        "en": "English",
        "hu": "Magyar"
    ]
}
