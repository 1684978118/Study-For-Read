import 'package:flutter/material.dart';

import 'review_controller.dart';
import 'vocabulary_card_tile.dart';
import 'vocabulary_controller.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({
    super.key,
    VocabularyController? controller,
    ReviewController? reviewController,
  }) : _controller = controller,
       _reviewController = reviewController;

  final VocabularyController? _controller;
  final ReviewController? _reviewController;

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
          );
        }

        return const Scaffold(
          appBar: _VocabularyAppBar(),
          body: Center(child: Text('Loading vocabulary...')),
        );
      },
    );
  }
}

class _VocabularyContent extends StatelessWidget {
  const _VocabularyContent({
    required this.controller,
    required this.reviewController,
  });

  final VocabularyController controller;
  final ReviewController? reviewController;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const _VocabularyAppBar(),
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
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
                  emptyBody: 'Saved lookup cards will stay available offline.',
                  errorMessage: controller.errorMessage,
                  onRefresh: controller.load,
                  reviewController: reviewController,
                  onReviewed: controller.load,
                ),
                _VocabularyList(
                  cards: controller.privateSentenceCards,
                  emptyTitle: 'No private sentence cards yet',
                  emptyBody: 'Private sentence cards are shown only for you.',
                  errorMessage: controller.errorMessage,
                  onRefresh: controller.load,
                  reviewController: reviewController,
                  onReviewed: controller.load,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VocabularyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _VocabularyAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(
    kToolbarHeight + kTextTabBarHeight,
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Vocabulary'),
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

  Future<void> _review({
    required String cardId,
    required bool known,
  }) async {
    await reviewController!.reviewCard(cardId: cardId, known: known);
    await onReviewed();
  }
}

class _EmptyVocabularyState extends StatelessWidget {
  const _EmptyVocabularyState({
    required this.title,
    required this.body,
  });

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
