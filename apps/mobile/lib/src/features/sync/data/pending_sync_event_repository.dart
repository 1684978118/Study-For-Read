import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/pending_sync_event.dart';

class PendingSyncEventRepository {
  PendingSyncEventRepository(this._db);

  final DatabaseExecutor _db;

  Future<int> insert(PendingSyncEvent event) {
    _validate(event);
    return _db.insert('pending_sync_events', event.toMap());
  }

  Future<List<PendingSyncEvent>> findPendingByOwnerUserId(
    String ownerUserId,
  ) async {
    final rows = await _db.query(
      'pending_sync_events',
      where: 'owner_user_id = ? AND status = ?',
      whereArgs: [ownerUserId, 'pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map(PendingSyncEvent.fromMap).toList(growable: false);
  }

  void _validate(PendingSyncEvent event) {
    if (event.attemptCount < 0) {
      throw ArgumentError('attemptCount must be zero or positive');
    }
    const allowedEventTypes = {
      'book_metadata',
      'reading_progress',
      'word_card_create',
      'word_card_review',
      'daily_stats',
    };
    if (!allowedEventTypes.contains(event.eventType)) {
      throw ArgumentError('Unsupported event_type');
    }
    const allowedStatuses = {'pending', 'in_progress', 'failed', 'done'};
    if (!allowedStatuses.contains(event.status)) {
      throw ArgumentError('Unsupported status');
    }
    _rejectForbiddenPayloadFields(event.payloadJson);
  }

  void _rejectForbiddenPayloadFields(String payloadJson) {
    final decoded = jsonDecode(payloadJson);
    if (_containsForbiddenKey(decoded)) {
      throw ArgumentError('payload_json contains forbidden content');
    }
  }

  bool _containsForbiddenKey(Object? value) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (_isForbiddenKey(key)) {
          return true;
        }
        if (_containsForbiddenKey(entry.value)) {
          return true;
        }
      }
    } else if (value is Iterable) {
      for (final item in value) {
        if (_containsForbiddenKey(item)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isForbiddenKey(String key) {
    final normalized = key.replaceAll('_', '').toLowerCase();
    const forbidden = <String>{
      'content',
      'chaptercontent',
      'originalfile',
      'filepath',
      'rawtext',
      'sourcetexthash',
      'sourcetextpreview',
      'translatedtext',
      'paragraphtext',
      'fullchapter',
      'fullbook',
      'originalfilepath',
    };
    return forbidden.contains(normalized);
  }
}
