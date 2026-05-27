package com.example.aprender

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "aprender/widget_scores"
    private val preferencesName = "aprender_widget_scores"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getScores" -> result.success(getScores())
                "updateWidgets" -> {
                    updateWidgets()
                    result.success(null)
                }
                "saveScore" -> {
                    val game = call.argument<String>("game")
                    val score = call.argument<Number>("score")?.toInt() ?: 0

                    if (game == null) {
                        result.error("invalid_game", "Game is required", null)
                        return@setMethodCallHandler
                    }

                    saveScore(game, score)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getScores(): Map<String, Int> {
        val preferences = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

        return mapOf(
            "quizMyBrain" to preferences.getInt("quizMyBrain", 0),
            "geniusPlay" to preferences.getInt("geniusPlay", 0),
            "memoCheck" to preferences.getInt("memoCheck", 0)
        )
    }

    private fun saveScore(game: String, score: Int) {
        val saved = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            .edit()
            .putInt(game, score)
            .commit()

        if (saved) {
            updateWidgets()
        }
    }

    private fun updateWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        val component = ComponentName(this, Widget11Provider::class.java)
        val ids = manager.getAppWidgetIds(component)
        Widget11Provider.updateWidgets(this, manager, ids)
    }
}
