import Cocoa
import FirebaseAuth
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Called from Dart after Firebase.initializeApp() to disable keychain
    // access groups — avoids errSecMissingEntitlement without a paid certificate.
    let channel = FlutterMethodChannel(
      name: "app.sabros/auth_config",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "fixMacOSKeychain" {
        try? Auth.auth().useUserAccessGroup(nil)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
