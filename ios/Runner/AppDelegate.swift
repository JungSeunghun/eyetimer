import UIKit
import Flutter
import ActivityKit
import AudioToolbox

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "com.eyetimer.timerActivity"
    var timerActivity: Activity<TimerAttributes>?

    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "startTimer":
                if let args = call.arguments as? [String: Any] {
                    let title = args["title"] as? String ?? "타이머 시작"
                    let message = args["message"] as? String ?? "타이머 시작"
                    self.startTimerActivity(title: title, message: message)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "arguments missing", details: nil))
                }
            case "updateTimer":
                if let args = call.arguments as? [String: Any] {
                    let title = args["title"] as? String ?? "타이머 업데이트"
                    let message = args["message"] as? String ?? "타이머 업데이트"
                    self.updateTimerActivity(title: title, message: message)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "arguments missing", details: nil))
                }
            case "endTimer":
                self.endTimerActivity()
                result(nil)
            case "pauseTimer":
                let title = (call.arguments as? [String: Any])?["title"] as? String ?? "타이머 일시정지"
                let message = (call.arguments as? [String: Any])?["message"] as? String ?? "타이머가 일시정지되었습니다."
                self.pauseTimerActivity(title: title, message: message)
                result(nil)
            case "resumeTimer":
                let title = (call.arguments as? [String: Any])?["title"] as? String ?? "타이머 재개"
                let message = (call.arguments as? [String: Any])?["message"] as? String ?? "타이머가 재개되었습니다."
                self.resumeTimerActivity(title: title, message: message)
                result(nil)
            case "switchTimer":   // 모드 전환 시 호출되는 새로운 메서드
                if let args = call.arguments as? [String: Any] {
                    let title = args["title"] as? String ?? "타이머 전환"
                    let message = args["message"] as? String ?? "타이머 모드 전환됨"
                    self.switchTimerActivity(title: title, message: message)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "arguments missing", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ActivityKit을 위한 속성 정의 (attributes는 빈 구조체)
    struct TimerAttributes: ActivityAttributes {
        public typealias ContentState = TimerStatus
    }

    // TimerStatus는 title, message, isPaused만 포함합니다.
    struct TimerStatus: Codable, Hashable {
        var isPaused: Bool
        var title: String
        var message: String
    }

    @available(iOS 16.1, *)
    func startTimerActivity(title: String, message: String) {
        let attributes = TimerAttributes()
        let initialState = TimerStatus(isPaused: false, title: title, message: message)
        do {
            timerActivity = try Activity<TimerAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
        } catch {
            print("Live Activity 시작 오류: \(error)")
        }
    }

    @available(iOS 16.1, *)
    func updateTimerActivity(title: String, message: String) {
        guard let activity = timerActivity else { return }
        let updatedState = TimerStatus(isPaused: activity.contentState.isPaused, title: title, message: message)
        Task {
            await activity.update(using: updatedState)
        }
    }

    @available(iOS 16.1, *)
    func pauseTimerActivity(title: String, message: String) {
        guard let activity = timerActivity else { return }
        let updatedState = TimerStatus(isPaused: true, title: title, message: message)
        Task {
            await activity.update(using: updatedState)
        }
    }

    @available(iOS 16.1, *)
    func resumeTimerActivity(title: String, message: String) {
        guard let activity = timerActivity else { return }
        let updatedState = TimerStatus(isPaused: false, title: title, message: message)
        Task {
            await activity.update(using: updatedState)
        }
    }

    @available(iOS 16.1, *)
    func endTimerActivity() {
        guard let activity = timerActivity else { return }
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        timerActivity = nil
    }

    // 새로운 모드 전환 메서드: Live Activity 업데이트 후 소리와 진동 재생
    @available(iOS 16.1, *)
    func switchTimerActivity(title: String, message: String) {
        guard let activity = timerActivity else { return }
        let updatedState = TimerStatus(isPaused: activity.contentState.isPaused, title: title, message: message)
        Task {
            await activity.update(using: updatedState)
        }
        playSwitchSoundAndVibration()
    }

    // 소리와 진동을 재생하는 함수
    func playSwitchSoundAndVibration() {
        // 시스템 사운드 ID 1007 (예시)로 소리 재생
        AudioServicesPlaySystemSound(SystemSoundID(1007))
        // 진동 재생
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
