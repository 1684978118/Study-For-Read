import 'package:sqflite/sqflite.dart';

import '../domain/local_word_card.dart';

class LocalWordCardRepository {
  LocalWordCardRepository(this._db);

  final DatabaseExecutor _db;

  Future<void> upsert(LocalWordCard card) async {
    _validate(card);
    final rows = await _db.query(
      'local_word_cards',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [card.id],
      limit: 1,
    );
    if (rows.isEmpty) {
      await _db.insert('local_word_cards', card.toMap());
    } else {
      await _db.update(
        'local_word_cards',
        card.toMap(),
        where: 'id = ?',
        whereArgs: [card.id],
      );
    }
  }

  Future<LocalWordCard?> findById(String id) async {
    final rows = await _db.query(
      'local_word_cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return LocalWordCard.fromMap(rows.single);
  }

  Future<List<LocalWordCard>> findByOwnerUserId(String ownerUserId) async {
    final rows = await _db.query(
      'local_word_cards',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(LocalWordCard.fromMap).toList(growable: false);
  }

  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    final rows = await _db.query(
      'local_word_cards',
      where: 'owner_user_id = ? AND card_type = ?',
      whereArgs: [ownerUserId, 'private_sentence'],
      orderBy: 'updated_at DESC',
    );
    return rows.map(LocalWordCard.fromMap).toList(growable: false);
  }

  Future<List<LocalWordCard>> findDueByOwnerUserId({
    required String ownerUserId,
    required DateTime dueAt,
  }) async {
    final rows = await _db.query(
      'local_word_cards',
      where:
          'owner_user_id = ? AND '
          "(review_status = 'new' OR "
          '(next_review_at IS NOT NULL AND next_review_at <= ?))',
      whereArgs: [ownerUserId, dueAt.toUtc().toIso8601String()],
      orderBy: 'next_review_at ASC, created_at ASC',
    );
    return rows.map(LocalWordCard.fromMap).toList(growable: false);
  }

  Future<int> updateReviewState({
    required String id,
    required String reviewStatus,
    required int reviewCount,
    required DateTime? nextReviewAt,
    required DateTime? lastReviewedAt,
    required String syncStatus,
    required DateTime updatedAt,
  }) {
    if (reviewCount < 0) {
      throw ArgumentError('reviewCount must be zero or positive');
    }
    return _db.update(
      'local_word_cards',
      {
        'review_status': reviewStatus,
        'review_count': reviewCount,
        'next_review_at': nextReviewAt?.toUtc().toIso8601String(),
        'last_reviewed_at': lastReviewedAt?.toUtc().toIso8601String(),
        'sync_status': syncStatus,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  void _validate(LocalWordCard card) {
    if (card.cardType == 'lexeme') {
      if (_isBlank(card.lexemeId)) {
        throw ArgumentError('lexeme_id is required for lexeme cards');
      }
    } else if (card.cardType == 'private_sentence') {
      if (_isBlank(card.privateSurface) || _isBlank(card.privateDefinition)) {
        throw ArgumentError(
          'private_surface and private_definition are required',
        );
      }
    } else {
      throw ArgumentError('Unsupported card_type');
    }

    if (card.reviewCount < 0) {
      throw ArgumentError('reviewCount must be zero or positive');
    }
  }

  bool _isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }
}
