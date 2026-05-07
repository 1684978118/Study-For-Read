package com.studyforread.server.reading;

import com.studyforread.server.reading.dto.BookMetadataRequest;
import com.studyforread.server.reading.dto.BookListResponse;
import com.studyforread.server.reading.dto.BookResponse;
import com.studyforread.server.reading.dto.ReadingProgressRequest;
import com.studyforread.server.reading.dto.ReadingProgressResponse;
import com.studyforread.server.user.UserAccountRepository;
import jakarta.persistence.EntityManager;
import java.time.OffsetDateTime;
import java.util.Comparator;
import java.util.UUID;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReadingService {

    private final ObjectProvider<UserBookRepository> userBookRepositoryProvider;
    private final ObjectProvider<UserAccountRepository> userAccountRepositoryProvider;
    private final ObjectProvider<EntityManager> entityManagerProvider;

    public ReadingService(
            ObjectProvider<UserBookRepository> userBookRepositoryProvider,
            ObjectProvider<UserAccountRepository> userAccountRepositoryProvider,
            ObjectProvider<EntityManager> entityManagerProvider) {
        this.userBookRepositoryProvider = userBookRepositoryProvider;
        this.userAccountRepositoryProvider = userAccountRepositoryProvider;
        this.entityManagerProvider = entityManagerProvider;
    }

    @Transactional
    public BookResponse upsertBookMetadata(UUID userId, String bookFingerprint, BookMetadataRequest request) {
        var userBookRepository = required(userBookRepositoryProvider);
        var userAccountRepository = required(userAccountRepositoryProvider);
        var user = userAccountRepository.findById(userId).orElseThrow(CurrentUserNotFoundException::new);
        var fileType = BookFileType.fromDatabaseValue(request.fileType());
        var existing = userBookRepository.findByUserIdAndBookFingerprint(userId, bookFingerprint);

        var book = existing.map(userBook -> updateExistingBook(userBook, request, fileType))
                .orElseGet(() -> userBookRepository.saveAndFlush(new UserBook(
                        user,
                        bookFingerprint,
                        request.title(),
                        request.author(),
                        fileType,
                        request.sourceLang(),
                        request.targetLang(),
                        request.chapterCount(),
                        0,
                        0,
                        0,
                        null)));

        return toResponse(book);
    }

    @Transactional
    public ReadingProgressResponse updateProgress(UUID userId, String bookFingerprint, ReadingProgressRequest request) {
        var userBookRepository = required(userBookRepositoryProvider);
        var book = userBookRepository.findByUserIdAndBookFingerprint(userId, bookFingerprint)
                .orElseThrow(BookNotFoundException::new);

        updateExistingProgress(book, request);
        var updatedBook = userBookRepository.findById(book.getId()).orElseThrow();
        return toProgressResponse(updatedBook);
    }

    @Transactional(readOnly = true)
    public BookListResponse listBooks(UUID userId) {
        var userBookRepository = required(userBookRepositoryProvider);
        var items = userBookRepository.findByUserIdOrderByLastReadAtDesc(userId).stream()
                .sorted(Comparator
                        .comparing(UserBook::getLastReadAt, Comparator.nullsLast(Comparator.reverseOrder()))
                        .thenComparing(UserBook::getCreatedAt, Comparator.reverseOrder()))
                .map(this::toResponse)
                .toList();

        return new BookListResponse(items);
    }

    private UserBook updateExistingBook(UserBook book, BookMetadataRequest request, BookFileType fileType) {
        var entityManager = required(entityManagerProvider);
        var userBookRepository = required(userBookRepositoryProvider);
        entityManager.createQuery("""
                        update UserBook book
                        set book.title = :title,
                            book.author = :author,
                            book.fileType = :fileType,
                            book.sourceLang = :sourceLang,
                            book.targetLang = :targetLang,
                            book.chapterCount = :chapterCount,
                            book.updatedAt = :updatedAt
                        where book.id = :id
                        """)
                .setParameter("title", request.title())
                .setParameter("author", request.author())
                .setParameter("fileType", fileType.databaseValue())
                .setParameter("sourceLang", request.sourceLang())
                .setParameter("targetLang", request.targetLang())
                .setParameter("chapterCount", request.chapterCount())
                .setParameter("updatedAt", OffsetDateTime.now())
                .setParameter("id", book.getId())
                .executeUpdate();
        entityManager.flush();
        entityManager.clear();

        return userBookRepository.findById(book.getId()).orElseThrow();
    }

    private void updateExistingProgress(UserBook book, ReadingProgressRequest request) {
        var entityManager = required(entityManagerProvider);
        entityManager.createQuery("""
                        update UserBook book
                        set book.currentChapterIndex = :currentChapterIndex,
                            book.currentParagraphIndex = :currentParagraphIndex,
                            book.currentCharOffset = :currentCharOffset,
                            book.lastReadAt = :lastReadAt,
                            book.updatedAt = :updatedAt
                        where book.id = :id
                        """)
                .setParameter("currentChapterIndex", request.currentChapterIndex())
                .setParameter("currentParagraphIndex", request.currentParagraphIndex())
                .setParameter("currentCharOffset", request.currentCharOffset())
                .setParameter("lastReadAt", request.lastReadAt())
                .setParameter("updatedAt", OffsetDateTime.now())
                .setParameter("id", book.getId())
                .executeUpdate();
        entityManager.flush();
        entityManager.clear();
    }

    private <T> T required(ObjectProvider<T> provider) {
        return provider.getIfAvailable(() -> {
            throw new IllegalStateException("Reading persistence is not available");
        });
    }

    private BookResponse toResponse(UserBook book) {
        return new BookResponse(
                book.getId(),
                book.getBookFingerprint(),
                book.getTitle(),
                book.getAuthor(),
                book.getFileType().databaseValue(),
                book.getSourceLang(),
                book.getTargetLang(),
                book.getChapterCount(),
                book.getCurrentChapterIndex(),
                book.getCurrentParagraphIndex(),
                book.getCurrentCharOffset(),
                book.getLastReadAt());
    }

    private ReadingProgressResponse toProgressResponse(UserBook book) {
        return new ReadingProgressResponse(
                book.getBookFingerprint(),
                book.getCurrentChapterIndex(),
                book.getCurrentParagraphIndex(),
                book.getCurrentCharOffset(),
                book.getLastReadAt());
    }

    public static class CurrentUserNotFoundException extends RuntimeException {
    }

    public static class BookNotFoundException extends RuntimeException {
    }
}
