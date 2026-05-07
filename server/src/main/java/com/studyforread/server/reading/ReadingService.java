package com.studyforread.server.reading;

import com.studyforread.server.reading.dto.BookMetadataRequest;
import com.studyforread.server.reading.dto.BookResponse;
import com.studyforread.server.user.UserAccountRepository;
import jakarta.persistence.EntityManager;
import java.time.OffsetDateTime;
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

    public static class CurrentUserNotFoundException extends RuntimeException {
    }
}
