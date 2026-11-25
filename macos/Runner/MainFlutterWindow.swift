import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Launch in mobile phone aspect ratio
    var frame = self.frame
    frame.size = NSSize(width: 410, height: 840)
    self.setFrame(frame, display: true)
    self.title = "Minar"
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
