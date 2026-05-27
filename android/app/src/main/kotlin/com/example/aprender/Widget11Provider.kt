package com.example.aprender

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class Widget11Provider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        private const val preferencesName = "aprender_widget_scores"

        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
            val quizScore = preferences.getInt("quizMyBrain", 0).toString()
            val geniusScore = preferences.getInt("geniusPlay", 0).toString()
            val memoScore = preferences.getInt("memoCheck", 0).toString()

            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.widget11)
                views.setTextViewText(R.id.quiz_score, quizScore)
                views.setTextViewText(R.id.genius_score, geniusScore)
                views.setTextViewText(R.id.memo_score, memoScore)
                views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }

        private fun openAppIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
