import AppKit

// LSUIElement: no dock icon, menu bar only
// Set via Info.plist in the app bundle

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
