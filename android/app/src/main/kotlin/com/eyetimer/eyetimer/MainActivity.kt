package com.eyetimer.eyetimer

import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.eyetimer.timerActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTimer" -> {
                        val title = call.argument<String>("title") ?: "타이머 시작"
                        val message = call.argument<String>("message") ?: "타이머 시작"
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_START
                            putExtra("title", title)
                            putExtra("message", message)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "updateTimer" -> {
                        val title = call.argument<String>("title") ?: "타이머 업데이트"
                        val message = call.argument<String>("message") ?: "타이머 업데이트"
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_UPDATE
                            putExtra("title", title)
                            putExtra("message", message)
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "endTimer" -> {
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_END
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "pauseTimer" -> {
                        val title = call.argument<String>("title") ?: "타이머 일시정지"
                        val message = call.argument<String>("message") ?: "타이머가 일시정지되었습니다."
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_PAUSE
                            putExtra("title", title)
                            putExtra("message", message)
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "resumeTimer" -> {
                        val title = call.argument<String>("title") ?: "타이머 재개"
                        val message = call.argument<String>("message") ?: "타이머가 재개되었습니다."
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_RESUME
                            putExtra("title", title)
                            putExtra("message", message)
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "switchTimer" -> {  // 새 메서드 추가
                        val title = call.argument<String>("title") ?: "타이머 전환"
                        val message = call.argument<String>("message") ?: "타이머 모드 전환됨"
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_SWITCH
                            putExtra("title", title)
                            putExtra("message", message)
                        }
                        startService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
