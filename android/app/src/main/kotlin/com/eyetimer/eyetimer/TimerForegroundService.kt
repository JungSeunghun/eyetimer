package com.eyetimer.eyetimer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.AssetFileDescriptor
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class TimerForegroundService : Service() {

    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "timer_channel"
        const val CHANNEL_NAME = "Timer Channel"
        const val ACTION_START = "ACTION_START"
        const val ACTION_UPDATE = "ACTION_UPDATE"
        const val ACTION_END = "ACTION_END"
        const val ACTION_PAUSE = "ACTION_PAUSE"
        const val ACTION_RESUME = "ACTION_RESUME"
        const val ACTION_SWITCH = "ACTION_SWITCH"
    }

    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START
        val title = intent?.getStringExtra("title") ?: ""
        val message = intent?.getStringExtra("message") ?: ""
        when (action) {
            ACTION_START -> {
                // TimerProvider에서 전달한 whiteNoiseAsset 값을 가져옵니다.
                val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val asset = prefs.getString("flutter.white_noise_asset", "") ?: ""
                val notification = buildInitialNotification(title, message)
                startForeground(NOTIFICATION_ID, notification)
                if (asset.isNotEmpty()) {
                    playWhiteNoiseWithAsset(asset)
                }
            }
            ACTION_UPDATE -> {
                val notification = buildUpdateNotification(title, message)
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_SWITCH -> {
                val notification = buildInitialNotification(title, message)
                val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_PAUSE -> {
                val notification = buildUpdateNotification(title, message)
                val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
                pauseWhiteNoise()
                // FlutterEngine를 통해 pause 이벤트 전송 (캐시된 FlutterEngine "my_engine_id" 사용)
                val flutterEngine: FlutterEngine? = FlutterEngineCache.getInstance().get("my_engine_id")
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, "com.eyetimer.timerActivity")
                        .invokeMethod("onPauseNotification", null)
                }
            }
            ACTION_RESUME -> {
                val notification = buildUpdateNotification(title, message)
                val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
                resumeWhiteNoise()
                val flutterEngine: FlutterEngine? = FlutterEngineCache.getInstance().get("my_engine_id")
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, "com.eyetimer.timerActivity")
                        .invokeMethod("onResumeNotification", null)
                }
            }
            ACTION_END -> {
                stopWhiteNoise()
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        return PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun createResumePendingIntent(): PendingIntent {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = ACTION_RESUME
        }
        return PendingIntent.getService(this, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun createPausePendingIntent(): PendingIntent {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = ACTION_PAUSE
        }
        return PendingIntent.getService(this, 2, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    // 초기 알림: 재생/정지 버튼 포함 (MediaStyle 사용하여 컴팩트 뷰에 노출)
    private fun buildInitialNotification(title: String, message: String): Notification {
        val pendingIntent = createPendingIntent()
        val resumeIntent = createResumePendingIntent()
        val pauseIntent = createPausePendingIntent()

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentIntent(pendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.mipmap.launcher_icon)
            .addAction(NotificationCompat.Action(android.R.drawable.ic_media_play, "play", resumeIntent))
            .addAction(NotificationCompat.Action(android.R.drawable.ic_media_pause, "pause", pauseIntent))
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .build()
    }

    // 업데이트 알림: 동일한 버튼 포함
    private fun buildUpdateNotification(title: String, message: String): Notification {
        val pendingIntent = createPendingIntent()
        val resumeIntent = createResumePendingIntent()
        val pauseIntent = createPausePendingIntent()

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentIntent(pendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.mipmap.launcher_icon)
            .addAction(NotificationCompat.Action(android.R.drawable.ic_media_play, "play", resumeIntent))
            .addAction(NotificationCompat.Action(android.R.drawable.ic_media_pause, "pause", pauseIntent))
            .setOngoing(true)
            .setSound(null)
            .setVibrate(null)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = "Channel for timer notifications"
                val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                setSound(
                    defaultSoundUri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    // 선택된 자산 경로를 사용하여 화이트 노이즈 재생 (항상 처음부터 재생)
    private fun playWhiteNoiseWithAsset(asset: String) {
        try {
            val assetKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer()
            val afd: AssetFileDescriptor = assets.openFd(assetKey)
            mediaPlayer?.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            mediaPlayer?.prepare()
            mediaPlayer?.isLooping = true
            mediaPlayer?.seekTo(0)
            mediaPlayer?.start()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun pauseWhiteNoise() {
        mediaPlayer?.pause()
    }

    private fun resumeWhiteNoise() {
        mediaPlayer?.start()
    }

    private fun stopWhiteNoise() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }
}
