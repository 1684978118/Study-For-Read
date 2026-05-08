import 'package:flutter/material.dart';

import '../export/anki_export_service.dart';
import 'anki_export_screen.dart';
import 'review_controller.dart';
import 'vocabulary_card_tile.dart';
import 'vocabulary_controller.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({
    super.key,
    VocabularyController? controller,
    ReviewController? reviewController,
    AnkiExportService ankiExportService = const AnkiExportService(),
  }) : _controller = controller,
       _reviewController = reviewController,
       _ankiExportService = ankiExportService;

  final VocabularyController? _controller;
  final ReviewController? _reviewController;
  final AnkiExportService _ankiExportService;

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  VocabularyController? _controller;
  ReviewController? _reviewController;
  Future<_VocabularyControllers>? _controllersFuture;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final controller = widget._controller;
    if (controller != null) {
      _controller = controller;
      _reviewController = widget._reviewController;
      controller.load();
    } else {
      _ownsController = true;
      _controllersFuture = _VocabularyControllers.local();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller?.dispose();
      _reviewController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return _VocabularyContent(
        controller: controller,
        reviewController: _reviewController,
        ankiExportService: widget._ankiExportService,
      );
    }

    return FutureBuilder<_VocabularyControllers>(
      future: _controllersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _controller = snapshot.requireData.vocabularyController;
          _reviewController = snapshot.requireData.reviewController;
          _controller!.load();
          return _VocabularyContent(
            controller: _controller!,
            reviewController: _reviewController,
            ankiExportService: widget._ankiExportService,
          );
        }

        return const DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: _VocabularyAppBar(),
            body: Center(child: Text('Loading vocabulary...')),
          ),
        );
      },
    );
  }
}

class _VocabularyContent extends StatelessWidget {
  const _VocabularyContent({
    required this.controller,
    required this.reviewController,
    required this.ankiExportService,
  });

  final VocabularyController controller;
  final ReviewController? reviewController;
  final AnkiExportService ankiExportService;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Scaffold(
            appBar: _VocabularyAppBar(
              allCards: _toAnkiCards(controller.allCards),
              dueCards: _toAnkiCards(controller.dueCards),
              privateSentenceCards: _toAnkiCards(
                controller.privateSentenceCards,
              ),
              ankiExportService: ankiExportService,
            ),
            body: Builder(
              builder: (context) {
                if (controller.isLoading && controller.allCards.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  children: [
                    _VocabularyList(
                      cards: controller.dueCards,
                      emptyTitle: 'No cards due now',
                      emptyBody: 'New and scheduled cards will appear here.',
                      errorMessage: controller.errorMessage,
                      onRefresh: controller.load,
                      reviewController: reviewController,
                      onReviewed: controller.load,
                    ),
                    _VocabularyList(
                      cards: controller.allCards,
                      emptyTitle: 'No vocabulary cards yet',
                      emptyBody:
                          'Saved lookup cards will stay available offline.',
                      errorMessage: controller.errorMessage,
                      onRefresh: controller.load,
                      reviewController: reviewController,
                      onReviewed: controller.load,
                    ),
                    _VocabularyList(
                      cards: controller.privateSentenceCards,
                      emptyTitle: 'No private sentence cards yet',
                      emptyBody:
                          'Private sentence cards are shown only for you.',
                      errorMessage: controller.errorMessage,
                      onRefresh: controller.load,
                      reviewController: reviewController,
                      onReviewed: controller.load,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _VocabularyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _VocabularyAppBar({
    this.allCards = const [],
    this.dueCards = const [],
    this.privateSentenceCards = const [],
    this.ankiExportService = const AnkiExportService(),
  });

  final List<AnkiExportCard> allCards;
  final List<AnkiExportCard> dueCards;
  final List<AnkiExportCard> privateSentenceCards;
  final AnkiExportService ankiExportService;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Vocabulary'),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => AnkiExportScreen(
                service: ankiExportService,
                allCards: allCards,
                dueCards: dueCards,
                privateSentenceCards: privateSentenceCards,
              ),
            ),
          ),
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Export'),
        ),
      ],
      bottom: const TabBar(
        tabs: [
          Tab(text: 'Due'),
          Tab(text: 'All'),
          Tab(text: 'Private Sentences'),
        ],
      ),
    );
  }
}

List<AnkiExportCard> _toAnkiCards(List<VocabularyCardView> cards) {
  return [
    for (final card in cards)
      AnkiExportCard(
        id: card.id,
        front: card.surface,
        reading: card.reading,
        meaning: card.definition,
        example: card.isPrivateSentence ? card.privateContext : null,
        tags: [
          card.isPrivateSentence ? 'private_sentence' : 'lexeme',
          card.reviewStatus,
        ],
      ),
  ];
}

class _VocabularyList extends StatelessWidget {
  const _VocabularyList({
    required this.cards,
    required this.emptyTitle,
    required this.emptyBody,
    required this.errorMessage,
    required this.onRefresh,
    required this.reviewController,
    required this.onReviewed,
  });

  final List<VocabularyCardView> cards;
  final String emptyTitle;
  final String emptyBody;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ReviewController? reviewController;
  final Future<void> Function() onReviewed;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (errorMessage != null) _InlineError(message: errorMessage!),
          if (cards.isEmpty)
            _EmptyVocabularyState(title: emptyTitle, body: emptyBody)
          else
            for (final card in cards)
              VocabularyCardTile(
                card: card,
                onKnown: reviewController == null
                    ? null
                    : (cardId) => _review(cardId: cardId, known: true),
                onUnknown: reviewController == null
                    ? null
                    : (cardId) => _review(cardId: cardId, known: false),
              ),
        ],
      ),
    );
  }

  Future<void> _review({required String cardId, required bool known}) async {
    await reviewController!.reviewCard(cardId: cardId, known: known);
    await onReviewed();
  }
}

class _EmptyVocabularyState extends StatelessWidget {
  const _EmptyVocabularyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.58,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.style_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _VocabularyControllers {
  const _VocabularyControllers({
    required this.vocabularyController,
    required this.reviewController,
  });

  final VocabularyController vocabularyController;
  final ReviewController reviewController;

  static Future<_VocabularyControllers> local() async {
    final vocabularyController = await VocabularyController.local();
    final reviewController = await ReviewController.local();
    return _VocabularyControllers(
      vocabularyController: vocabularyController,
      reviewController: reviewController,
    );
  }
}
