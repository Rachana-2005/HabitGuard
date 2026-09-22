package com.habitguard.habitguard

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.habitguard/usage"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    openUsageSettings()
                    result.success(true)
                }
                "getTodayUsage" -> {
                    try {
                        val calendar = Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }
                        val startTime = calendar.timeInMillis
                        val endTime = System.currentTimeMillis()
                        val usageList = fetchUsageStats(startTime, endTime)
                        result.success(usageList)
                    } catch (e: Exception) {
                        result.error("USAGE_STATS_ERROR", e.localizedMessage, null)
                    }
                }
                "getUsageForDate" -> {
                    try {
                        val startTime = call.argument<Long>("startTime") ?: 0L
                        val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                        val usageList = fetchUsageStats(startTime, endTime)
                        result.success(usageList)
                    } catch (e: Exception) {
                        result.error("USAGE_STATS_ERROR", e.localizedMessage, null)
                    }
                }
                "getUsageForRange" -> {
                    try {
                        val startTime = call.argument<Long>("startTime") ?: 0L
                        val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                        val usageList = fetchUsageStats(startTime, endTime)
                        result.success(usageList)
                    } catch (e: Exception) {
                        result.error("USAGE_STATS_ERROR", e.localizedMessage, null)
                    }
                }
                "getPastDaysUsage" -> {
                    try {
                        val days = call.argument<Int>("days") ?: 7
                        val historyList = fetchPastDaysHistory(days)
                        result.success(historyList)
                    } catch (e: Exception) {
                        result.error("USAGE_STATS_ERROR", e.localizedMessage, null)
                    }
                }
                "getBehavioralMetrics" -> {
                    try {
                        val startTime = call.argument<Long>("startTime") ?: getTodayStartMillis()
                        val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                        val metrics = fetchBehavioralMetrics(startTime, endTime)
                        result.success(metrics)
                    } catch (e: Exception) {
                        result.error("BEHAVIORAL_METRICS_ERROR", e.localizedMessage, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getTodayStartMillis(): Long {
        return Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            try {
                val fallbackIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(fallbackIntent)
            } catch (ignored: Exception) {
            }
        }
    }

    private fun fetchPastDaysHistory(days: Int): List<Map<String, Any>> {
        val history = mutableListOf<Map<String, Any>>()
        for (i in (days - 1) downTo 0) {
            val startCal = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -i)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val endCal = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -i)
                if (i == 0) {
                    timeInMillis = System.currentTimeMillis()
                } else {
                    set(Calendar.HOUR_OF_DAY, 23)
                    set(Calendar.MINUTE, 59)
                    set(Calendar.SECOND, 59)
                    set(Calendar.MILLISECOND, 999)
                }
            }

            val year = startCal.get(Calendar.YEAR)
            val month = String.format("%02d", startCal.get(Calendar.MONTH) + 1)
            val day = String.format("%02d", startCal.get(Calendar.DAY_OF_MONTH))
            val dateKey = "$year-$month-$day"

            val usageList = fetchUsageStats(startCal.timeInMillis, endCal.timeInMillis)
            val dayEntry = HashMap<String, Any>().apply {
                put("date", dateKey)
                put("timestamp", startCal.timeInMillis)
                put("applications", usageList)
            }
            history.add(dayEntry)
        }
        return history
    }

    private fun fetchUsageStats(startTime: Long, endTime: Long): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return emptyList()

        val packageManager: PackageManager = applicationContext.packageManager

        // Identify default home launcher package to avoid counting idle home screen
        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val defaultLauncherPkg = packageManager.resolveActivity(homeIntent, PackageManager.MATCH_DEFAULT_ONLY)?.activityInfo?.packageName

        val systemBlacklist = setOf(
            "android",
            "com.android.systemui",
            "com.google.android.gms",
            "com.google.android.inputmethod.latin",
            "com.samsung.android.honeyboard",
            "com.touchtype.swiftkey",
            "com.vivo.upslide",
            "com.bbk.launcher2",
            "com.vivo.launcher",
            "com.vivo.daemonService",
            "com.habitguard.habitguard"
        )

        // Query daily usage stats
        val usageStatsList: List<UsageStats> = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        ) ?: emptyList()

        val appUsageMap = HashMap<String, Long>()
        val appFirstUsedMap = HashMap<String, Long>()
        val appLastUsedMap = HashMap<String, Long>()

        for (stats in usageStatsList) {
            val pkgName = stats.packageName ?: continue
            val lastUsed = stats.lastTimeUsed

            if (lastUsed < startTime) {
                continue
            }

            val exactOnScreenDuration = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val visible = stats.totalTimeVisible
                if (visible > 0) visible else stats.totalTimeInForeground
            } else {
                stats.totalTimeInForeground
            }

            if (exactOnScreenDuration > 0) {
                val prev = appUsageMap[pkgName] ?: 0L
                if (exactOnScreenDuration > prev) {
                    appUsageMap[pkgName] = exactOnScreenDuration
                    appFirstUsedMap[pkgName] = stats.firstTimeStamp
                    appLastUsedMap[pkgName] = stats.lastTimeUsed
                }
            }
        }

        // Fallback to queryAndAggregateUsageStats if daily slice was empty
        if (appUsageMap.isEmpty()) {
            val aggregateMap = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime) ?: emptyMap()
            for ((pkgName, stats) in aggregateMap) {
                val lastUsed = stats.lastTimeUsed
                if (lastUsed >= startTime) {
                    val duration = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val v = stats.totalTimeVisible
                        if (v > 0) v else stats.totalTimeInForeground
                    } else {
                        stats.totalTimeInForeground
                    }
                    if (duration > 0) {
                        appUsageMap[pkgName] = duration
                        appFirstUsedMap[pkgName] = stats.firstTimeStamp
                        appLastUsedMap[pkgName] = stats.lastTimeUsed
                    }
                }
            }
        }

        // Get session counts via UsageEvents if available
        val sessionCountMap = querySessionCounts(usageStatsManager, startTime, endTime)

        val results = mutableListOf<Map<String, Any>>()

        for ((pkgName, totalTimeForeground) in appUsageMap) {
            // Must have at least 5 seconds of visible screen time
            if (totalTimeForeground < 5000) {
                continue
            }

            // Exclude system UI, keyboards, launchers, and HabitGuard itself
            if (systemBlacklist.contains(pkgName) || pkgName == defaultLauncherPkg || pkgName == packageName) {
                continue
            }

            // Must be a launchable user application
            val launchIntent = packageManager.getLaunchIntentForPackage(pkgName)
            if (launchIntent == null) {
                continue
            }

            var appLabel = pkgName
            try {
                val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    packageManager.getApplicationInfo(pkgName, PackageManager.ApplicationInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    packageManager.getApplicationInfo(pkgName, 0)
                }
                val label = packageManager.getApplicationLabel(appInfo).toString()
                if (label.isNotBlank()) {
                    appLabel = label
                }
            } catch (e: Exception) {
                val parts = pkgName.split(".")
                if (parts.isNotEmpty()) {
                    val lastPart = parts.last()
                    if (lastPart.isNotEmpty()) {
                        appLabel = lastPart.replaceFirstChar { it.uppercase() }
                    }
                }
            }

            val appEntry = HashMap<String, Any>().apply {
                put("packageName", pkgName)
                put("applicationName", appLabel)
                put("usageMilliseconds", totalTimeForeground)
                put("usageDuration", totalTimeForeground / 60000L) // Duration in minutes
                put("firstTimeUsed", appFirstUsedMap[pkgName] ?: startTime)
                put("lastTimeUsed", appLastUsedMap[pkgName] ?: endTime)
                put("numberOfSessions", sessionCountMap[pkgName] ?: 1)
            }
            results.add(appEntry)
        }

        results.sortByDescending { (it["usageMilliseconds"] as? Long) ?: 0L }
        return results
    }

    private fun querySessionCounts(usageStatsManager: UsageStatsManager, startTime: Long, endTime: Long): Map<String, Int> {
        val counts = mutableMapOf<String, Int>()
        try {
            val events = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()
            while (events != null && events.hasNextEvent()) {
                events.getNextEvent(event)
                val pkg = event.packageName ?: continue
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                    event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    counts[pkg] = (counts[pkg] ?: 0) + 1
                }
            }
        } catch (e: Exception) {
            // Fallback gracefully if event querying is not supported
        }
        return counts
    }

    private fun fetchBehavioralMetrics(startTime: Long, endTime: Long): Map<String, Any> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return mapOf(
                "totalSessions" to 0,
                "lateNightUsageMillis" to 0L,
                "earlyMorningUsageMillis" to 0L,
                "sessionCounts" to emptyMap<String, Int>()
            )

        val counts = mutableMapOf<String, Int>()
        var totalSessions = 0
        var lateNightUsageMillis = 0L
        var earlyMorningUsageMillis = 0L

        try {
            val events = usageStatsManager.queryEvents(startTime, endTime)
            val event = UsageEvents.Event()
            var currentForegroundPkg: String? = null
            var currentForegroundStart = 0L
            val cal = Calendar.getInstance()

            while (events != null && events.hasNextEvent()) {
                events.getNextEvent(event)
                val pkg = event.packageName ?: continue
                val timestamp = event.timeStamp

                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                    event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    totalSessions++
                    counts[pkg] = (counts[pkg] ?: 0) + 1
                    currentForegroundPkg = pkg
                    currentForegroundStart = timestamp
                } else if (event.eventType == UsageEvents.Event.ACTIVITY_PAUSED ||
                    event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND) {
                    if (currentForegroundPkg == pkg && currentForegroundStart > 0L) {
                        val duration = timestamp - currentForegroundStart
                        if (duration in 1..86400000) {
                            cal.timeInMillis = currentForegroundStart
                            val hour = cal.get(Calendar.HOUR_OF_DAY)
                            // Late night: 23:00 to 05:00
                            if (hour >= 23 || hour < 5) {
                                lateNightUsageMillis += duration
                            } else if (hour in 5..6) {
                                // Early morning: 05:00 to 07:00
                                earlyMorningUsageMillis += duration
                            }
                        }
                        currentForegroundStart = 0L
                        currentForegroundPkg = null
                    }
                }
            }
        } catch (e: Exception) {
            // Graceful fallback
        }

        return mapOf(
            "totalSessions" to totalSessions,
            "lateNightUsageMillis" to lateNightUsageMillis,
            "earlyMorningUsageMillis" to earlyMorningUsageMillis,
            "sessionCounts" to counts
        )
    }
}
