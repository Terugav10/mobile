import 'package:flutter/services.dart';

class WidgetScores {
  static const MethodChannel _channel = MethodChannel('aprender/widget_scores');

  static Future<Map<String, int>> getScores() async {
    Map<String, dynamic>? result;

    try {
      await _channel.invokeMethod<void>('updateWidgets');
      result = await _channel.invokeMapMethod<String, dynamic>('getScores');
    } on MissingPluginException {
      result = null;
    }

    return {
      'quizMyBrain': (result?['quizMyBrain'] as num?)?.toInt() ?? 0,
      'geniusPlay': (result?['geniusPlay'] as num?)?.toInt() ?? 0,
      'memoCheck': (result?['memoCheck'] as num?)?.toInt() ?? 0,
    };
  }

  static Future<void> saveScore(String game, int score) async {
    try {
      await _channel.invokeMethod<void>('saveScore', {
        'game': game,
        'score': score,
      });
      await _channel.invokeMethod<void>('updateWidgets');
    } on MissingPluginException {
      return;
    }
  }

  static Future<void> updateWidgets() async {
    try {
      await _channel.invokeMethod<void>('updateWidgets');
    } on MissingPluginException {
      return;
    }
  }
}
