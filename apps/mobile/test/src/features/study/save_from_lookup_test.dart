import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/study/domain/lookup_result.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/lookup_bottom_sheet.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/lookup_controller.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/save_vocabulary_controller.dart';

void main() {
  testWidgets('lookup bottom sheet Save action uses save vocabulary controller', (
    tester,
  ) async {
    final saveController = _FakeSaveVocabularyController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LookupBottomSheet(
            controller: _FakeLookupController(),
            saveController: saveController,
            sourceBookFingerprint:
                '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
            sourceBookTitle: 'Kokoro',
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(saveController.savedLexemes, hasLength(1));
    expect(saveController.savedLexemes.single.id, 'lexeme-1');
    expect(saveController.sourceBookTitles.single, 'Kokoro');
    expect(find.text('已保存'), findsOneWidget);
  });

  testWidgets('translated paragraphs do not show save sentence controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Column(children: [Text('原文段落'), Text('译文段落')])),
      ),
    );

    expect(find.text('Save sentence'), findsNothing);
    expect(find.text('Save private sentence'), findsNothing);
  });
}

class _FakeLookupController extends LookupController {
  _FakeLookupController() : super.test() {
    state = const LookupState.success(
      LookupResult(
        kind: 'lexeme',
        lexeme: LookupLexeme(
          id: 'lexeme-1',
          surface: '心',
          reading: 'こころ',
          entryType: 'word',
          partOfSpeech: 'noun',
          definition: 'heart; mind',
          shortDefinition: 'heart',
        ),
        provider: 'public_lexeme',
      ),
    );
  }
}

class _FakeSaveVocabularyController extends SaveVocabularyController {
  _FakeSaveVocabularyController() : super.test();

  final List<LookupLexeme> savedLexemes = [];
  final List<String?> sourceBookTitles = [];

  @override
  Future<void> saveLookupLexeme(
    LookupLexeme lexeme, {
    String? sourceBookFingerprint,
    String? sourceBookTitle,
    DateTime? now,
  }) async {
    savedLexemes.add(lexeme);
    sourceBookTitles.add(sourceBookTitle);
    setStateForTesting(const SaveVocabularyState.saved());
  }
}
