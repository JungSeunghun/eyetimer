package com.eyetimer.eyetimer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
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
        const val ACTION_SWITCH = "ACTION_SWITCH"  // 모드 전환 시 사용
    }

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
                val notification = buildInitialNotification(title, message)
                startForeground(NOTIFICATION_ID, notification)
            }
            ACTION_UPDATE,
            ACTION_PAUSE,
            ACTION_RESUME -> {
                val notification = buildUpdateNotification(title, message)
                val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_SWITCH -> {  // 모드 전환 시 알림 업데이트 (소리/진동 포함)
                val notification = buildInitialNotification(title, message)
                val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
            ACTION_END -> {
                stopForeground(true)
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
            // 앱이 이미 실행 중인 경우 기존 작업 스택을 재사용하도록 설정합니다.
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        // FLAG_IMMUTABLE는 API 23 이상부터 사용하는 것이 좋습니다.
        return PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    // 초기 알림: 소리와 진동 등 기본 알림 효과 포함
    private fun buildInitialNotification(title: String, message: String): Notification {
        val pendingIntent = createPendingIntent()
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentIntent(pendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(true)
            .build()
    }

    // 업데이트 알림: 이미 표시된 알림을 업데이트하며, 소리·진동은 발생하지 않음
    private fun buildUpdateNotification(title: String, message: String): Notification {
        val pendingIntent = createPendingIntent()
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentIntent(pendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(true)
            .setSound(null)                   // 소리 제거
            .setVibrate(null)                 // 진동 제거
            .setOnlyAlertOnce(true)           // 최초 알림 이후엔 경고음 발생 안함
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = "Channel for timer notifications"
                // 기본 알림 소리 설정 (기본 알림 소리 사용)
                val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                setSound(
                    defaultSoundUri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                // 진동 사용 및 패턴 설정
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
