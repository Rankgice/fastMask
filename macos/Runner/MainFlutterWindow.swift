import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // The main window is hidden behind the menu-bar entry at launch. Start it
    // fully transparent so AppKit/Flutter never paints a black rectangle before
    // Dart calls windowManager.hide().
    self.alphaValue = 0

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Apply the window chrome after Flutter has finished configuring its
    // content controller. This keeps AppKit from restoring a light title bar
    // after the initial nib load.
    self.appearance = NSAppearance(named: .darkAqua)
    self.backgroundColor = NSColor(
      calibratedRed: 32.0 / 255.0,
      green: 33.0 / 255.0,
      blue: 36.0 / 255.0,
      alpha: 1.0
    )
    self.title = "FastMask"
    self.titleVisibility = .visible
    self.titlebarAppearsTransparent = true
    self.titlebarSeparatorStyle = .none
    self.isOpaque = true
    self.hasShadow = true

    // Register the tray here as well as from the app delegate. Depending on
    // the launch path, the window's view controller may be ready first.
    (NSApp.delegate as? AppDelegate)?.setupNativeTray(with: flutterViewController)
  }
}
