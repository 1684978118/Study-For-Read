import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_lexeme_repository.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_lexeme.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/vocabulary_controller.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/vocabulary_screen.dart';

void main() {
  testWidgets('Vocabulary screen has compact mobile tabs', (tester) async {
    await tester.pumpWidget(_app(_controller(cards: [])));
    await tester.pumpAndSettle();

    expect(find.text('Due'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('Private Sentences'), findsNothing);
  });

  testWidgets('shows loading state while cards load', (tester) async {
    final controller = _controller(
      loadCards: () async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return [];
      },
    );

    await tester.pumpWidget(_app(controller));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('Due tab shows only cards due now', (tester) async {
    final now = DateTime.utc(2026, 5, 8, 12);
    final controller = _controller(
      now: now,
      cards: [
        _lexemeCard(id: 'card-1', lexemeId: 'lexeme-1'),
        _lexemeCard(
          id: 'card-2',
          lexemeId: 'lexeme-2',
          nextReviewAt: now.add(const Duration(days: 1)),
        ),
      ],
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.text('心'), findsOneWidget);
    expect(find.text('明日'), findsNothing);
  });

  testWidgets('All and Private Sentences tabs filter card types', (
    tester,
  ) async {
    final controller = _controller(
      cards: [
        _lexemeCard(id: 'card-1', lexemeId: 'lexeme-1'),
        _privateCard(id: 'private-1'),
        _privateCard(
          id: 'other-private',
          ownerUserId: 'user-2',
          privateSurface: 'Other sentence',
          privateDefinition: 'Other definition',
          privateContext: 'Other private context',
        ),
      ],
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('心'), findsOneWidget);
    expect(find.text('私だけの文'), findsOneWidget);

    await tester.tap(find.text('Private'));
    await tester.pumpAndSettle();

    expect(find.text('私だけの文'), findsOneWidget);
    expect(find.text('Private meaning'), findsOneWidget);
    expect(find.text('My private context'), findsOneWidget);
    expect(find.text('心'), findsNothing);
    expect(find.textContaining('Other'), findsNothing);
  });

  testWidgets('empty states are distinct for due and all cards', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller(cards: [])));
    await tester.pumpAndSettle();

    expect(find.text('No cards due now'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('No vocabulary cards yet'), findsOneWidget);
  });
}

Widget _app(VocabularyController controller) {
  return MaterialApp(home: VocabularyScreen(controller: controller));
}

VocabularyController _controller({
  List<LocalWordCard>? cards,
  Future<List<LocalWordCard>> Function()? loadCards,
  DateTime? now,
}) {
  return VocabularyController(
    ownerUserId: 'user-1',
    wordCardRepository: _FakeWordCardRepository(
      cards: cards ?? const [],
      loadCards: loadCards,
    ),
    lexemeRepository: _FakeLexemeRepository({
      'lexeme-1': _lexeme(id: 'lexeme-1', surface: '心'),
      'lexeme-2': _lexeme(id: 'lexeme-2', surface: '明日'),
    }),
    now: () => now ?? DateTime.utc(2026, 5, 8, 12),
  );
}

LocalLexeme _lexeme({required String id, required String surface}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalLexeme(
    id: id,
    surface: surface,
    reading: 'reading-$id',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: 'definition-$id',
    shortDefinition: 'short-$id',
    cachedAt: now,
    updatedAt: now,
  );
}

LocalWordCard _lexemeCard({
  required String id,
  String ownerUserId = 'user-1',
  required String lexemeId,
  DateTime? nextReviewAt,
}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalWordCard(
    id: id,
    serverCardId: null,
    ownerUserId: ownerUserId,
    cardType: 'lexeme',
    lexemeId: lexemeId,
    privateSurface: null,
    privateDefinition: null,
    privateContext: null,
    sourceBookFingerprint: null,
    sourceBookTitle: null,
    reviewStatus: 'new',
    reviewCount: 0,
    nextReviewAt: nextReviewAt,
    lastReviewedAt: null,
    syncStatus: 'local_only',
    createdAt: now,
    updatedAt: now,
  );
}

LocalWordCard _privateCard({
  required String id,
  String ownerUserId = 'user-1',
  String privateSurface = '私だけの文',
  String privateDefinition = 'Private meaning',
  String privateContext = 'My private context',
}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalWordCard(
    id: id,
    serverCardId: null,
    ownerUserId: ownerUserId,
    cardType: 'private_sentence',
    lexemeId: null,
    privateSurface: privateSurface,
    privateDefinition: privateDefinition,
    privateContext: privateContext,
    sourceBookFingerprint: null,
    sourceBookTitle: null,
    reviewStatus: 'learning',
    reviewCount: 2,
    nextReviewAt: null,
    lastReviewedAt: null,
    syncStatus: 'local_only',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeWordCardRepository implements LocalWordCardRepository {
  const _FakeWordCardRepository({required this.cards, this.loadCards});

  final List<LocalWordCard> cards;
  final Future<List<LocalWordCard>> Function()? loadCards;

  Future<List<LocalWordCard>> _currentCards() async {
    final loader = loadCards;
    return loader == null ? cards : loader();
  }

  @override
  Future<List<LocalWordCard>> findByOwnerUserId(String ownerUserId) async {
    final rows = await _currentCards();
    return rows
        .where((card) => card.ownerUserId == ownerUserId)
        .toList(growable: false);
  }

  @override
  Future<List<LocalWordCard>> findDueByOwnerUserId({
    required String ownerUserId,
    required DateTime dueAt,
  }) async {
    final rows = await _currentCards();
    return rows
        .where(
          (card) =>
              card.ownerUserId == ownerUserId &&
              (card.nextReviewAt == null || !card.nextReviewAt!.isAfter(dueAt)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    final rows = await _currentCards();
    return rows
        .where(
          (card) =>
              card.ownerUserId == ownerUserId &&
              card.cardType == 'private_sentence',
        )
        .toList(growable: false);
  }

  @override
  Future<LocalWordCard?> findById(String id) async => null;

  @override
  Future<LocalWordCard?> findByOwnerUserIdAndLexemeId({
    required String ownerUserId,
    required String lexemeId,
  }) async {
    return null;
  }

  @override
  Future<void> upsert(LocalWordCard card) async {}

  @override
  Future<int> updateReviewState({
    required String id,
    required String reviewStatus,
    required int reviewCount,
    required DateTime? nextReviewAt,
    required DateTime? lastReviewedAt,
    required String syncStatus,
    required DateTime updatedAt,
  }) async {
    return 0;
  }
}

class _FakeLexemeRepository implements LocalLexemeRepository {
  const _FakeLexemeRepository(this.lexemes);

  final Map<String, LocalLexeme> lexemes;

  @override
  Future<LocalLexeme?> findById(String id) async => lexemes[id];

  @override
  Future<void> upsert(LocalLexeme lexeme) async {}
}
