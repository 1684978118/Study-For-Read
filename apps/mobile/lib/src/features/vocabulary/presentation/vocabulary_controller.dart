import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/database/mobile_database.dart';
import '../../auth/data/auth_token_store.dart';
import '../../study/data/local_lexeme_repository.dart';
import '../../study/domain/local_lexeme.dart';
import '../data/local_word_card_repository.dart';
import '../domain/local_word_card.dart';

class VocabularyCardView {
  const VocabularyCardView({
    required this.id,
    required this.cardType,
    required this.surface,
    this.reading,
    required this.definition,
    this.privateContext,
    required this.reviewStatus,
    required this.reviewCount,
    this.nextReviewAt,
    required this.syncStatus,
  });

  final String id;
  final String cardType;
  final String surface;
  final String? reading;
  final String definition;
  final String? privateContext;
  final String reviewStatus;
  final int reviewCount;
  final DateTime? nextReviewAt;
  final String syncStatus;

  bool get isPrivateSentence => cardType == 'private_sentence';
}

class VocabularyController extends ChangeNotifier {
  VocabularyController({
    required String ownerUserId,
    required LocalWordCardRepository wordCardRepository,
    required LocalLexemeRepository lexemeRepository,
    DateTime Function()? now,
  }) : _ownerUserId = ownerUserId,
       _wordCardRepository = wordCardRepository,
       _lexemeRepository = lexemeRepository,
       _now = now ?? DateTime.now;

  final String _ownerUserId;
  final LocalWordCardRepository _wordCardRepository;
  final LocalLexemeRepository _lexemeRepository;
  final DateTime Function() _now;

  bool _isLoading = false;
  String? _errorMessage;
  List<VocabularyCardView> _dueCards = const [];
  List<VocabularyCardView> _allCards = const [];
  List<VocabularyCardView> _privateSentenceCards = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<VocabularyCardView> get dueCards => _dueCards;
  List<VocabularyCardView> get allCards => _allCards;
  List<VocabularyCardView> get privateSentenceCards => _privateSentenceCards;

  static Future<VocabularyController> local() async {
    final ownerUserId = await _readCurrentUserId(SecureAuthTokenStore());
    final database = await MobileDatabase().open();
    return VocabularyController(
      ownerUserId: ownerUserId,
      wordCardRepository: LocalWordCardRepository(database),
      lexemeRepository: LocalLexemeRepository(database),
    );
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dueAt = _now().toUtc();
      final due = await _wordCardRepository.findDueByOwnerUserId(
        ownerUserId: _ownerUserId,
        dueAt: dueAt,
      );
      final all = await _wordCardRepository.findByOwnerUserId(_ownerUserId);
      final privateSentences = await _wordCardRepository
          .findPrivateSentenceByOwnerUserId(_ownerUserId);

      _dueCards = await _toViews(due);
      _allCards = await _toViews(all);
      _privateSentenceCards = await _toViews(privateSentences);
    } catch (_) {
      _errorMessage = '无法加载词卡。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<VocabularyCardView>> _toViews(List<LocalWordCard> cards) async {
    final views = <VocabularyCardView>[];
    for (final card in cards) {
      views.add(await _toView(card));
    }
    return List.unmodifiable(views);
  }

  Future<VocabularyCardView> _toView(LocalWordCard card) async {
    if (card.cardType == 'private_sentence') {
      return VocabularyCardView(
        id: card.id,
        cardType: card.cardType,
        surface: card.privateSurface ?? '私密例句',
        definition: card.privateDefinition ?? '',
        privateContext: card.privateContext,
        reviewStatus: card.reviewStatus,
        reviewCount: card.reviewCount,
        nextReviewAt: card.nextReviewAt,
        syncStatus: card.syncStatus,
      );
    }

    final lexeme = await _findLexeme(card.lexemeId);
    return VocabularyCardView(
      id: card.id,
      cardType: card.cardType,
      surface: lexeme?.surface ?? card.lexemeId ?? '未知词条',
      reading: lexeme?.reading,
      definition: lexeme?.definition ?? '离线状态下无法显示释义',
      reviewStatus: card.reviewStatus,
      reviewCount: card.reviewCount,
      nextReviewAt: card.nextReviewAt,
      syncStatus: card.syncStatus,
    );
  }

  Future<LocalLexeme?> _findLexeme(String? lexemeId) {
    if (lexemeId == null || lexemeId.isEmpty) {
      return Future.value();
    }
    return _lexemeRepository.findById(lexemeId);
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

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final payloadParts = payload.split(':');
    if (payloadParts.length != 3 || payloadParts.first.isEmpty) {
      throw StateError('Invalid access token payload');
    }

    return payloadParts.first;
  }
}
