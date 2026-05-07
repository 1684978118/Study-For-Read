package com.studyforread.server.vocabulary;

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
@Table(name = "user_word_cards")
public class UserWordCard {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserAccount user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lexeme_id")
    private Lexeme lexeme;

    @Column(name = "card_type", nullable = false, length = 32)
    private String cardType;

    @Column(name = "private_surface", length = 500)
    private String privateSurface;

    @Column(name = "private_definition", columnDefinition = "text")
    private String privateDefinition;

    @Column(name = "private_context", columnDefinition = "text")
    private String privateContext;

    @Column(name = "source_book_fingerprint", length = 64, columnDefinition = "char(64)")
    private String sourceBookFingerprint;

    @Column(name = "source_book_title", length = 255)
    private String sourceBookTitle;

    @Column(name = "review_status", nullable = false, length = 32)
    private String reviewStatus;

    @Column(name = "review_count", nullable = false)
    private int reviewCount;

    @Column(name = "next_review_at", columnDefinition = "timestamp with time zone")
    private OffsetDateTime nextReviewAt;

    @Column(name = "last_reviewed_at", columnDefinition = "timestamp with time zone")
    private OffsetDateTime lastReviewedAt;

    @Column(name = "created_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime updatedAt;

    protected UserWordCard() {
    }

    public UserWordCard(
            UserAccount user,
            Lexeme lexeme,
            WordCardType cardType,
            String privateSurface,
            String privateDefinition,
            String privateContext,
            String sourceBookFingerprint,
            String sourceBookTitle,
            ReviewStatus reviewStatus,
            int reviewCount,
            OffsetDateTime nextReviewAt,
            OffsetDateTime lastReviewedAt) {
        this.user = user;
        this.lexeme = lexeme;
        this.cardType = cardType.databaseValue();
        this.privateSurface = privateSurface;
        this.privateDefinition = privateDefinition;
        this.privateContext = privateContext;
        this.sourceBookFingerprint = sourceBookFingerprint;
        this.sourceBookTitle = sourceBookTitle;
        this.reviewStatus = reviewStatus.databaseValue();
        this.reviewCount = reviewCount;
        this.nextReviewAt = nextReviewAt;
        this.lastReviewedAt = lastReviewedAt;
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

    public Lexeme getLexeme() {
        return lexeme;
    }

    public WordCardType getCardType() {
        return WordCardType.fromDatabaseValue(cardType);
    }

    public String getPrivateSurface() {
        return privateSurface;
    }

    public String getPrivateDefinition() {
        return privateDefinition;
    }

    public String getPrivateContext() {
        return privateContext;
    }

    public String getSourceBookFingerprint() {
        return sourceBookFingerprint;
    }

    public String getSourceBookTitle() {
        return sourceBookTitle;
    }

    public ReviewStatus getReviewStatus() {
        return ReviewStatus.fromDatabaseValue(reviewStatus);
    }

    public int getReviewCount() {
        return reviewCount;
    }

    public OffsetDateTime getNextReviewAt() {
        return nextReviewAt;
    }

    public OffsetDateTime getLastReviewedAt() {
        return lastReviewedAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
