import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate, NSMenuDelegate {
  private static let trayChannelName = "fastmask/native_tray"

  private var statusItem: NSStatusItem?
  private var trayChannel: FlutterMethodChannel?
  private var lengthMode = "preserve"
  private var token = "*"

  override func applicationWillFinishLaunching(_ notification: Notification) {
    // FastMask is a menu-bar utility. Keep it out of the Dock and app switcher
    // even when it is launched outside LaunchServices during development.
    NSApp.setActivationPolicy(.accessory)
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    if let flutterViewController = mainFlutterWindow?.contentViewController as? FlutterViewController {
      setupNativeTray(with: flutterViewController)
    }
  }

  func setupNativeTray(with flutterViewController: FlutterViewController) {
    guard trayChannel == nil, statusItem == nil else {
      return
    }

    let channel = FlutterMethodChannel(
      name: Self.trayChannelName,
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleTrayMethod(call, result: result)
    }
    trayChannel = channel

    createStatusItem()
    NSLog("FastMask: native macOS tray is ready.")
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // FastMask lives in the menu bar and intentionally keeps its window hidden.
    // Closing or hiding the last window must not terminate the application.
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func handleTrayMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "bad_arguments", message: "Missing tray arguments.", details: nil))
      return
    }

    switch call.method {
    case "configureTray":
      lengthMode = arguments["lengthMode"] as? String ?? lengthMode
      token = arguments["token"] as? String ?? token
      createStatusItem()
      rebuildMenu()
      result(nil)
    case "updateTrayMenu":
      lengthMode = arguments["lengthMode"] as? String ?? lengthMode
      token = arguments["token"] as? String ?? token
      rebuildMenu()
      result(nil)
    case "destroyTray":
      if let statusItem {
        NSStatusBar.system.removeStatusItem(statusItem)
      }
      statusItem = nil
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func createStatusItem() {
    guard statusItem == nil else {
      return
    }

    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    guard let button = item.button else {
      NSLog("FastMask: unable to create the macOS status item button.")
      return
    }

    // Keep a short text label in addition to the symbol. A template symbol can
    // be difficult to distinguish from other monochrome menu-bar utilities,
    // and the text also acts as a visible fallback if SF Symbols is unavailable.
    button.title = "FM"
    button.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
    if let symbol = NSImage(
      systemSymbolName: "text.badge.xmark",
      accessibilityDescription: "FastMask"
    ) {
      symbol.isTemplate = true
      button.image = symbol
      button.imagePosition = .imageLeading
    } else {
      button.imagePosition = .noImage
    }

    button.toolTip = "FastMask · 快速模糊"
    button.setAccessibilityLabel("FastMask 菜单")

    statusItem = item
    item.isVisible = true
    NSLog("FastMask: status item created (button title: %@, visible: %@).",
          button.title, item.isVisible ? "yes" : "no")
    rebuildMenu()
  }

  private func rebuildMenu() {
    guard let item = statusItem else {
      return
    }

    let menu = NSMenu(title: "FastMask")
    menu.autoenablesItems = false

    menu.addItem(menuItem(title: "快速模糊", action: #selector(quickMaskClicked), keyEquivalent: "b"))
    menu.addItem(menuItem(title: "显示主界面", action: #selector(showWindowClicked)))
    menu.addItem(NSMenuItem.separator())

    let lengthMenu = NSMenu(title: "模糊长度")
    lengthMenu.autoenablesItems = false
    lengthMenu.addItem(lengthItem(title: "保持原长度", key: "length_preserve", mode: "preserve"))
    lengthMenu.addItem(lengthItem(title: "固定长度", key: "length_fixed", mode: "fixed"))
    lengthMenu.addItem(lengthItem(title: "按比例", key: "length_proportional", mode: "proportional"))
    lengthMenu.addItem(lengthItem(title: "随机范围", key: "length_random", mode: "randomRange"))

    let tokenMenu = NSMenu(title: "遮挡字符")
    tokenMenu.autoenablesItems = false
    tokenMenu.addItem(tokenItem(title: "*", key: "token_asterisk", value: "*"))
    tokenMenu.addItem(tokenItem(title: "█", key: "token_square", value: "█"))
    tokenMenu.addItem(tokenItem(title: "#", key: "token_hash", value: "#"))
    tokenMenu.addItem(tokenItem(title: "x", key: "token_x", value: "x"))

    let lengthParent = NSMenuItem(title: "模糊长度", action: nil, keyEquivalent: "")
    lengthParent.submenu = lengthMenu
    menu.addItem(lengthParent)

    let tokenParent = NSMenuItem(title: "遮挡字符", action: nil, keyEquivalent: "")
    tokenParent.submenu = tokenMenu
    menu.addItem(tokenParent)

    menu.addItem(NSMenuItem.separator())
    menu.addItem(menuItem(title: "隐藏窗口", action: #selector(hideWindowClicked)))
    menu.addItem(menuItem(title: "退出 FastMask", action: #selector(quitClicked)))

    item.menu = menu
  }

  private func menuItem(
    title: String,
    action: Selector,
    keyEquivalent: String = ""
  ) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    item.target = self
    if keyEquivalent == "b" {
      item.keyEquivalentModifierMask = [.command, .shift]
    }
    return item
  }

  private func lengthItem(title: String, key: String, mode: String) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: #selector(lengthModeClicked(_:)), keyEquivalent: "")
    item.target = self
    item.representedObject = mode
    item.state = lengthMode == mode ? .on : .off
    return item
  }

  private func tokenItem(title: String, key: String, value: String) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: #selector(tokenClicked(_:)), keyEquivalent: "")
    item.target = self
    item.representedObject = value
    item.state = token == value ? .on : .off
    return item
  }

  @objc private func quickMaskClicked() {
    sendTrayAction("quick_mask")
  }

  @objc private func showWindowClicked() {
    sendTrayAction("show_window")
  }

  @objc private func hideWindowClicked() {
    sendTrayAction("hide_window")
  }

  @objc private func quitClicked() {
    sendTrayAction("exit_app")
  }

  @objc private func lengthModeClicked(_ sender: NSMenuItem) {
    guard let mode = sender.representedObject as? String else {
      return
    }
    lengthMode = mode
    sendTrayAction("length_\(mode == "randomRange" ? "random" : mode)")
    rebuildMenu()
  }

  @objc private func tokenClicked(_ sender: NSMenuItem) {
    guard let value = sender.representedObject as? String else {
      return
    }
    token = value
    let key: String
    switch value {
    case "*": key = "token_asterisk"
    case "█": key = "token_square"
    case "#": key = "token_hash"
    default: key = "token_x"
    }
    sendTrayAction(key)
    rebuildMenu()
  }

  private func sendTrayAction(_ action: String) {
    trayChannel?.invokeMethod("trayAction", arguments: action)
  }
}
