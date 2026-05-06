package com.studyforread.server.reading;

import com.studyforread.server.user.UserAccount;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_books")
public class UserBook {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserAccount user;

    @Column(name = "book_fingerprint", nullable = false, length = 64, columnDefinition = "char(64)")
    private String bookFingerprint;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(length = 255)
    private String author;

    @Column(name = "file_type", nullable = false, length = 16)
    private String fileType;

    @Column(name = "source_lang", nullable = false, length = 16)
    private String sourceLang;

    @Column(name = "target_lang", nullable = false, length = 16)
    private String targetLang;

    @Column(name = "chapter_count", nullable = false)
    private int chapterCount;

    @Column(name = "current_chapter_index", nullable = false)
    private int currentChapterIndex;

    @Column(name = "current_paragraph_index", nullable = false)
    private int currentParagraphIndex;

    @Column(name = "current_char_offset", nullable = false)
    private int currentCharOffset;

    @Column(name = "last_read_at", columnDefinition = "timestamp with time zone")
    private OffsetDateTime lastReadAt;

    @Column(name = "created_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime updatedAt;

    protected UserBook() {
    }

    public UserBook(
            UserAccount user,
            String bookFingerprint,
            String title,
            String author,
            BookFileType fileType,
            String sourceLang,
            String targetLang,
            int chapterCount,
            int currentChapterIndex,
            int currentParagraphIndex,
            int currentCharOffset,
            OffsetDateTime lastReadAt) {
        this.user = user;
        this.bookFingerprint = bookFingerprint;
        this.title = title;
        this.author = author;
        this.fileType = fileType.databaseValue();
        this.sourceLang = sourceLang;
        this.targetLang = targetLang;
        this.chapterCount = chapterCount;
        this.currentChapterIndex = currentChapterIndex;
        this.currentParagraphIndex = currentParagraphIndex;
        this.currentCharOffset = currentCharOffset;
        this.lastReadAt = lastReadAt;
    }

    @PrePersist
    void prePersist() {
        if (id == null) {
            id = UUID.randomUUID();
        }

        var now = OffsetDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    public UUID getId() {
        return id;
    }

    public UserAccount getUser() {
        return user;
    }

    public String getBookFingerprint() {
        return bookFingerprint;
    }

    public String getTitle() {
        return title;
    }

    public String getAuthor() {
        return author;
    }

    public BookFileType getFileType() {
        return BookFileType.fromDatabaseValue(fileType);
    }

    public String getSourceLang() {
        return sourceLang;
    }

    public String getTargetLang() {
        return targetLang;
    }

    public int getChapterCount() {
        return chapterCount;
    }

    public int getCurrentChapterIndex() {
        return currentChapterIndex;
    }

    public int getCurrentParagraphIndex() {
        return currentParagraphIndex;
    }

    public int getCurrentCharOffset() {
        return currentCharOffset;
    }

    public OffsetDateTime getLastReadAt() {
        return lastReadAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
