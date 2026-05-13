import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/database/mobile_database.dart';
import '../../auth/data/auth_token_store.dart';
import '../data/local_study_stats_repository.dart';
import '../domain/study_stats_summary.dart';

class StatsController extends ChangeNotifier {
  StatsController({
    required String ownerUserId,
    required LocalStudyStatsRepository repository,
    DateTime Function()? now,
  }) : _ownerUserId = ownerUserId,
       _repository = repository,
       _now = now ?? DateTime.now;

  StatsController.fake({
    required StudyStatsSummary today,
    required StudyStatsSummary last7Days,
    required StudyStatsSummary allTime,
  }) : _ownerUserId = '',
       _repository = null,
       _now = DateTime.now,
       _today = today,
       _last7Days = last7Days,
       _allTime = allTime;

  final String _ownerUserId;
  final LocalStudyStatsRepository? _repository;
  final DateTime Function() _now;

  bool _isLoading = false;
  String? _errorMessage;
  StudyStatsSummary _today = StudyStatsSummary.zero;
  StudyStatsSummary _last7Days = StudyStatsSummary.zero;
  StudyStatsSummary _allTime = StudyStatsSummary.zero;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StudyStatsSummary get today => _today;
  StudyStatsSummary get last7Days => _last7Days;
  StudyStatsSummary get allTime => _allTime;

  static Future<StatsController> local() async {
    final ownerUserId = await _readCurrentUserId(SecureAuthTokenStore());
    final database = await MobileDatabase().open();
    return StatsController(
      ownerUserId: ownerUserId,
      repository: LocalStudyStatsRepository(database),
    );
  }

  Future<void> load() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = _now();
      _today = await repository.summaryForToday(
        ownerUserId: _ownerUserId,
        today: today,
      );
      _last7Days = await repository.summaryForLast7Days(
        ownerUserId: _ownerUserId,
        today: today,
      );
      _allTime = await repository.summaryForAllTime(ownerUserId: _ownerUserId);
    } catch (_) {
      _errorMessage = '无法加载学习统计。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static Future<String> _readCurrentUserId(AuthTokenStore tokenStore) async {
    final accessToken = await tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Missing access token');
    }

    final parts = accessToken.split('.');
    if (parts.length != 3 || parts[0] != 'access') {
      throw StateError('Invalid access token');
    }

    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final payloadParts = payload.split(':');
    if (payloadParts.length != 3 || payloadParts.first.isEmpty) {
      throw StateError('Invalid access token payload');
    }

    return payloadParts.first;
  }
}
