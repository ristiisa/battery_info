import Flutter
import UIKit

enum BatteryState {
  static let chargins = "charging"
  static let discharging = "discharging"
}

enum CustomFlutterErrorCode {
  static let unavailable = "UNAVAILABLE"
}


public class SwiftBatteryInfoPlugin: NSObject, FlutterPlugin {
  let generator = BatteryInfoGenerator()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.igrik12.battery_info/channel", binaryMessenger: registrar.messenger())
    let instance = SwiftBatteryInfoPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(name: "com.igrik12.battery_info/stream", binaryMessenger: messenger!)                                                                                
    eventChannel.setStreamHandler(SwiftBatteryInfoPlugin())
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let batteryInfo = generator.generate()
    let level: Int? = batteryInfo["batteryLevel"] as? Int
    if(level! < 0){
      result(FlutterError(code: CustomFlutterErrorCode.unavailable,
      message: "Battery level unavailable",
      details: nil))
    }
    let status: String? = batteryInfo["batteryStatus"] as? String
    if(status == CustomFlutterErrorCode.unavailable){
      result(FlutterError(code: CustomFlutterErrorCode.unavailable,
      message: "Battery status unavailable"))
    }
    result(batteryInfo)
  }
}

class SwiftStreamHandler: NSObject, FlutterStreamHandler {
  let generator = BatteryInfoGenerator()
  var eventSink: FlutterEventSink?

  
  public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    let batteryInfo = generator.generate()
    let level: Int? = batteryInfo["batteryLevel"] as? Int

    if(level! < 0){
      eventSink(FlutterError(code: CustomFlutterErrorCode.unavailable,
        message: "Battery level unavailable",
        details: nil))
      return nil
    }

    let status: String? = batteryInfo["batteryStatus"] as? String
    if(status == CustomFlutterErrorCode.unavailable){
      eventSink(FlutterError(code: CustomFlutterErrorCode.unavailable,
        message: "Battery status unavailable",
        details: nil))
      return nil
    }

    result(batteryInfo)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
} 

struct BatteryInfoGenerator{
    let device: UIDevice

    init(){
      device = UIDevice.current
      device.isBatteryMonitoringEnabled = true
    }

    private func sendBatteryState() {
      switch UIDevice.current.batteryState {
        case .full:
          return BatteryState.charging
        case .charging:
          return BatteryState.charging
        case .unplugged:
          return BatteryState.discharging
        default:
          return CustomFlutterErrorCode.unavailable
        }
    }

    private func getBatteryLevel() {
      Int(device.batteryLevel * 100)
    }

    func generate() -> Dictionary<String, Any>{
      var batteryInfo: [String: Any] = [:]
      batteryInfo["batteryLevel"] = getBatteryLevel()
      batteryInfo["batteryStatus"] = getBatteryStatus()
      return batteryInfo
    }
}