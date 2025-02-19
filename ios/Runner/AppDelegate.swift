import UIKit
import Flutter
import ActivityKit
import AVFoundation
import AudioToolbox

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "com.eyetimer.timerActivity"
    var timerActivity: Activity<TimerAttributes>?
    var audioPlayer: AVAudioPlayer?

    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        // MethodChannel 설정 및 핸들러 등록
        let methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        methodChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "startTimer":
                if let args = call.arguments as? [String: Any] {
                    let title = args["title"] as? String ?? "타이머 시작"
                    let message = args["message"] as? String ?? "타이머 시작"
                    // whiteNoiseAsset가 전달되면 화이트 노이즈 재생
                    let whiteNoiseAsset = args["whiteNoiseAsset"] as? String ?? ""
                    self.startTimerActivity(title: title, message: message)
                    if !whiteNoiseAsset.isEmpty {
                        self.playWhiteNoise(asset: whiteNoiseAsset)
                    }
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
            case "switchTimer":
                if let args = call.arguments as? [String: Any] {
                    let title = args["title"] as? String ?? "타이머 전환"
                    let message = args["message"] as? String ?? "타이머 모드 전환됨"
                    self.switchTimerActivity(title: title, message: message)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "arguments missing", details: nil))
                }
            case "playWhiteNoise":
                if let args = call.arguments as? [String: Any] {
                    let asset = args["whiteNoiseAsset"] as? String ?? ""
                    if !asset.isEmpty {
                        self.playWhiteNoise(asset: asset)
                    }
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "arguments missing", details: nil))
                }
            case "pauseWhiteNoise":
                self.pauseWhiteNoise()
                result(nil)
            case "resumeWhiteNoise":
                self.resumeWhiteNoise()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - ActivityKit (Live Activity) 관련

    struct TimerAttributes: ActivityAttributes {
        public typealias ContentState = TimerStatus
    }

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

    @available(iOS 16.1, *)
    func switchTimerActivity(title: String, message: String) {
        guard let activity = timerActivity else { return }
        let updatedState = TimerStatus(isPaused: activity.contentState.isPaused, title: title, message: message)
        Task {
            await activity.update(using: updatedState)
        }
        playSwitchSoundAndVibration()
    }

    func playSwitchSoundAndVibration() {
        AudioServicesPlaySystemSound(SystemSoundID(1007))
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    // MARK: - White Noise Playback (iOS)

    func playWhiteNoise(asset: String) {
        // asset가 "assets/sounds/ocean.mp3"처럼 Flutter 자산 경로라면,
        // 파일 이름만 추출하여 Xcode에 추가된 리소스로 로드합니다.
        let fileName = (asset as NSString).lastPathComponent
        let fileExtension = (fileName as NSString).pathExtension
        let resourceName = (fileName as NSString).deletingPathExtension

        guard let path = Bundle.main.path(forResource: resourceName, ofType: fileExtension) else {
            print("White noise asset not found: \(asset)")
            return
        }
        let url = URL(fileURLWithPath: path)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("White noise started")
        } catch {
            print("Error playing white noise: \(error)")
        }
    }

    func pauseWhiteNoise() {
        if let player = audioPlayer, player.isPlaying {
            player.pause()
            print("White noise paused")
        } else {
            print("White noise is not playing or already paused")
        }
    }

    func resumeWhiteNoise() {
        if let player = audioPlayer, !player.isPlaying {
            player.play()
            print("White noise resumed")
        } else {
            print("White noise is already playing")
        }
    }
}
