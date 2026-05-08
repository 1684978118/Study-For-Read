import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../domain/local_study_daily_stat.dart';
import '../domain/study_stats_summary.dart';

class LocalStudyStatsRepository {
  LocalStudyStatsRepository(this._db);

  final DatabaseExecutor _db;

  Future<LocalStudyDailyStat> increment({
    required String ownerUserId,
    required DateTime statDate,
    required int readingMinutes,
    required int lookupCount,
    required int paragraphTranslationCount,
    required int cardsCreated,
    required int cardsReviewed,
  }) async {
    _validateCounters(
      readingMinutes: readingMinutes,
      lookupCount: lookupCount,
      paragraphTranslationCount: paragraphTranslationCount,
      cardsCreated: cardsCreated,
      cardsReviewed: cardsReviewed,
    );

    final existing = await findByOwnerUserIdAndStatDate(
      ownerUserId: ownerUserId,
      statDate: statDate,
    );
    final now = DateTime.now().toUtc();
    final next = LocalStudyDailyStat(
      id: existing?.id ?? _uuidV4(),
      ownerUserId: ownerUserId,
      statDate: statDate,
      readingMinutes: (existing?.readingMinutes ?? 0) + readingMinutes,
      lookupCount: (existing?.lookupCount ?? 0) + lookupCount,
      paragraphTranslationCount:
          (existing?.paragraphTranslationCount ?? 0) +
          paragraphTranslationCount,
      cardsCreated: (existing?.cardsCreated ?? 0) + cardsCreated,
      cardsReviewed: (existing?.cardsReviewed ?? 0) + cardsReviewed,
      syncStatus: 'dirty',
      lastSyncedAt: existing?.lastSyncedAt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (existing == null) {
      await _db.insert('local_study_daily_stats', next.toMap());
    } else {
      await _db.update(
        'local_study_daily_stats',
        next.toMap(),
        where: 'id = ?',
        whereArgs: [next.id],
      );
    }

    return next;
  }

  Future<LocalStudyDailyStat?> findByOwnerUserIdAndStatDate({
    required String ownerUserId,
    required DateTime statDate,
  }) async {
    final rows = await _db.query(
      'local_study_daily_stats',
      where: 'owner_user_id = ? AND stat_date = ?',
      whereArgs: [ownerUserId, LocalStudyDailyStat.dateString(statDate)],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LocalStudyDailyStat.fromMap(rows.single);
  }

  Future<List<LocalStudyDailyStat>> findByOwnerUserId(
    String ownerUserId,
  ) async {
    final rows = await _db.query(
      'local_study_daily_stats',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
      orderBy: 'stat_date DESC',
    );
    return rows.map(LocalStudyDailyStat.fromMap).toList(growable: false);
  }

  void _validateCounters({
    required int readingMinutes,
    required int lookupCount,
    required int paragraphTranslationCount,
    required int cardsCreated,
    required int cardsReviewed,
  }) {
    final counters = [
      readingMinutes,
      lookupCount,
      paragraphTranslationCount,
      cardsCreated,
      cardsReviewed,
    ];
    if (counters.any((counter) => counter < 0)) {
      throw ArgumentError('counter increments must be zero or positive');
    }
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

extension LocalStudyStatsRepositorySummary on LocalStudyStatsRepository {
  Future<StudyStatsSummary> summaryForToday({
    required String ownerUserId,
    required DateTime today,
  }) async {
    final stat = await findByOwnerUserIdAndStatDate(
      ownerUserId: ownerUserId,
      statDate: today,
    );
    if (stat == null) {
      return StudyStatsSummary.zero;
    }
    return _summaryFrom(stat);
  }

  Future<StudyStatsSummary> summaryForLast7Days({
    required String ownerUserId,
    required DateTime today,
  }) async {
    final end = DateTime.utc(today.year, today.month, today.day);
    final start = end.subtract(const Duration(days: 6));
    final stats = await findByOwnerUserId(ownerUserId);
    return _sum(
      stats.where((stat) {
        final date = DateTime.utc(
          stat.statDate.year,
          stat.statDate.month,
          stat.statDate.day,
        );
        return !date.isBefore(start) && !date.isAfter(end);
      }),
    );
  }

  Future<StudyStatsSummary> summaryForAllTime({
    required String ownerUserId,
  }) async {
    final stats = await findByOwnerUserId(ownerUserId);
    return _sum(stats);
  }
}

StudyStatsSummary _sum(Iterable<LocalStudyDailyStat> stats) {
  var summary = StudyStatsSummary.zero;
  for (final stat in stats) {
    summary += _summaryFrom(stat);
  }
  return summary;
}

StudyStatsSummary _summaryFrom(LocalStudyDailyStat stat) {
  return StudyStatsSummary(
    readingMinutes: stat.readingMinutes,
    lookupCount: stat.lookupCount,
    paragraphTranslationCount: stat.paragraphTranslationCount,
    cardsCreated: stat.cardsCreated,
    cardsReviewed: stat.cardsReviewed,
  );
}
