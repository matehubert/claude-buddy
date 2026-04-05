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
            ? ["Szép commit!", "Hajrá!", "Kód commitolva!", "Jó mentés!", "Commitolva!",
               "Egy commit közelebb a kész kódhoz!", "Szép checkpoint!",
               "Elmentve az utókornak!"]
            : ["Nice commit!", "Ship it!", "Code committed!", "Good save!", "Committed!",
               "One commit closer to done!", "Nice checkpoint!",
               "Saved for posterity!"]
    }

    static var gitConflict: [String] {
        current == "hu"
            ? ["Jaj! Merge konflikt!", "Konflikt! Sok sikert!", "Ajaj, konfliktusok...",
               "Ütközés! Kitartás!", "Merge harc... melyik kód nyer?",
               "Konflikt detektálva... légy erős!"]
            : ["Yikes! Merge conflict!", "Conflict detected! Good luck!", "Uh oh, conflicts...",
               "Collision! Stay strong!", "Merge fight... which code wins?",
               "Conflict detected... be brave!"]
    }

    static var gitBranchSwitch: [String] {
        current == "hu"
            ? ["Új branch!", "Branch váltás!", "Másik branch!",
               "Ugrás másik ágra!", "Branch csere!",
               "Új ág, új kaland!"]
            : ["New branch!", "Branch switch!", "Different branch now!",
               "Jumping to another branch!", "Branch swap!",
               "New branch, new adventure!"]
    }

    static var gitPush: [String] {
        current == "hu"
            ? ["Pusholva!", "A kód kint van!", "Kitelepítve!",
               "Fent a kód a szerveren!", "Push sikeres!",
               "Világ, itt a kódom!"]
            : ["Pushed!", "Code is live!", "Deployed!",
               "Code is on the server!", "Push successful!",
               "World, here's my code!"]
    }

    static var gitDefault: String {
        current == "hu" ? "Git aktivitás!" : "Git activity!"
    }

    // MARK: - Clipboard Events

    static var clipboardLargePaste: [String] {
        current == "hu"
            ? ["Ez aztán a nagy paste!", "Sok kód!", "Kemény meló!",
               "Hatalmas paste!", "Ezt hol találtad?",
               "Copy-paste mester!", "Na ez nem kicsi..."]
            : ["Heavy lifting!", "That's a big paste!", "Lots of code!",
               "Massive paste!", "Where'd you find this?",
               "Copy-paste master!", "That's not small..."]
    }

    static var clipboardCodeCopy: [String] {
        current == "hu"
            ? ["Kódot másolsz?", "Ctrl+C elkapva!", "Kódrészlet!",
               "Jó kódrészlet!", "StackOverflow?",
               "Kód vágólapra!", "Snippetelünk?"]
            : ["Copying code?", "Ctrl+C detected!", "Code snippet!",
               "Nice snippet!", "StackOverflow?",
               "Code to clipboard!", "Snippeting?"]
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

    // MARK: - Active Window Events

    static func windowCodingInApp(_ app: String) -> String {
        let templates: [String] = current == "hu"
            ? ["Kódolás \(app)-ban!", "Hajrá, \(app)!", "Hmm, \(app)... mit építünk?",
               "Nyitva a \(app), mehet a kód!", "\(app) mód bekapcsolva!",
               "Lássuk mit hoz a \(app)!", "A \(app) vár, kódoljunk!"]
            : ["Coding in \(app)!", "Go \(app)!", "Hmm, \(app)... what are we building?",
               "\(app) is open, let's code!", "\(app) mode activated!",
               "Let's see what \(app) brings!", "\(app) awaits, let's code!"]
        return templates.randomElement()!
    }

    static var windowBrowser: [String] {
        current == "hu"
            ? ["Böngészés...", "Kutatás?", "StackOverflow idő?",
               "Hmm, dokumentáció olvasás?", "Google-ölünk?",
               "Remélem nem Reddit...", "Pár perc szörfölés~"]
            : ["Browsing...", "Research?", "StackOverflow time?",
               "Hmm, reading docs?", "Googling?",
               "Hope it's not Reddit...", "Quick surf~"]
    }

    static var windowOtherApp: [String] {
        current == "hu"
            ? ["Hmm, más app...", "Szünet?", "Vissza jössz kódolni?",
               "Oké, de ne felejtsd a kódot!", "Rövid kitérő?"]
            : ["Hmm, different app...", "Taking a break?", "Coming back to code?",
               "OK but don't forget the code!", "Quick detour?"]
    }

    // MARK: - File System Events

    static var fsCodingStorm: [String] {
        current == "hu"
            ? ["Kódvihar!!!", "Ennyi fájl egyszerre?!", "Őrült tempó!",
               "Whoa, ez refaktor?!", "Vihar a könyvtárban!",
               "Mindenütt változások!", "Valaki szorgalmas!"]
            : ["Coding storm!!!", "So many files!", "Wild pace!",
               "Whoa, refactoring?!", "Storm in the codebase!",
               "Changes everywhere!", "Someone's busy!"]
    }

    static var fsLotsOfChanges: [String] {
        current == "hu"
            ? ["Sok változás!", "Aktív kódolás!", "Jól megy!",
               "Haladunk!", "Jó tempó!", "Többfájlos szerkesztés!",
               "Rendesen benne vagy!"]
            : ["Lots of changes!", "Active coding!", "Going strong!",
               "Making progress!", "Good pace!", "Multi-file editing!",
               "Really in the zone!"]
    }

    static var fsFileActivity: [String] {
        current == "hu"
            ? ["Fájl változás!", "Mentés!", "*figyel*",
               "Módosítás megtörtént.", "Katt, mentve!",
               "Láttam, szerkesztettél~"]
            : ["File changed!", "Saved!", "*watching*",
               "Modification noted.", "Click, saved!",
               "I saw you edited~"]
    }

    // MARK: - Claude Code Hook Events

    static var hookSessionStart: [String] {
        current == "hu"
            ? ["Claude Code elindult!", "Új session!", "Hali, Claude!",
               "Megjött a segítség!", "Claude a színen!",
               "AI társprogramozó kész!", "Munkamenet indul!"]
            : ["Claude Code started!", "New session!", "Hi Claude!",
               "Help has arrived!", "Claude on the scene!",
               "AI pair programmer ready!", "Session starting!"]
    }

    static var hookSessionEnd: [String] {
        current == "hu"
            ? ["Session vége!", "Claude Code kész.", "Viszlát, Claude!",
               "Session befejezve!", "Claude kijelentkezik~",
               "Szép munka volt!"]
            : ["Session ended!", "Claude Code done.", "Bye Claude!",
               "Session complete!", "Claude signing off~",
               "Good work today!"]
    }

    static var hookRunningTests: [String] {
        current == "hu"
            ? ["Tesztek futnak!", "Teszt idő!", "Szorítok a zöldnek!",
               "Vajon átmegy?", "Jöjjenek a tesztek!",
               "CI energia... *szorít*", "Minden zöld lesz? 🤞"]
            : ["Running tests!", "Test time!", "Fingers crossed!",
               "Will it pass?", "Bring on the tests!",
               "CI vibes... *crossing fingers*", "All green? 🤞"]
    }

    static var hookBuilding: [String] {
        current == "hu"
            ? ["Build folyamatban!", "Fordítás...", "Építünk!",
               "Kompájlolunk...", "Mehet a build!",
               "Remélem nincs hiba...", "Fordítás indul..."]
            : ["Building!", "Compiling...", "Let's build!",
               "Compiling away...", "Build initiated!",
               "Hope there are no errors...", "Compilation started..."]
    }

    static var hookRunningCommand: [String] {
        current == "hu"
            ? ["Parancs fut!", "Terminal aktivitás!", "*gépelés*",
               "Valami fut a terminálban~", "Shell parancs!",
               "Lássuk mit csinál...", "Terminál munka!"]
            : ["Running command!", "Terminal activity!", "*typing*",
               "Something's running in terminal~", "Shell command!",
               "Let's see what it does...", "Terminal work!"]
    }

    static var hookWritingCode: [String] {
        current == "hu"
            ? ["Claude kódot ír!", "Kód készül!", "AI kódolás!",
               "Fájl szerkesztés!", "Nézzük mit ír...",
               "Kód generálás folyamatban~", "Claude dolgozik a kódon!",
               "Új sorok születnek!"]
            : ["Claude is writing code!", "Code incoming!", "AI coding!",
               "File being edited!", "Let's see what it writes...",
               "Code generation in progress~", "Claude working on code!",
               "New lines being born!"]
    }

    // MARK: - Hatch / Reroll Greeting

    static func hatchGreeting(name: String, species: String, rarity: String) -> String {
        let rarityStr = current == "hu" ? "Ritkaság: \(rarity)" : "Rarity: \(rarity)"
        return current == "hu"
            ? "Szia! \(name) vagyok, egy \(species)! \(rarityStr)"
            : "Hi! I'm \(name), a \(species)! \(rarityStr)"
    }

    static var hatchWelcome: [String] {
        current == "hu"
            ? ["Örülök hogy találkoztunk!", "Kódoljunk együtt!", "Készen állok!",
               "Új kaland kezdődik!", "Vigyázok rád kódolás közben~"]
            : ["Nice to meet you!", "Let's code together!", "I'm ready!",
               "A new adventure begins!", "I'll watch over you while you code~"]
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
