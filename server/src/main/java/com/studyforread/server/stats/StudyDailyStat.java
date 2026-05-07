package com.studyforread.server.stats;

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
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "study_daily_stats")
public class StudyDailyStat {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserAccount user;

    @Column(name = "stat_date", nullable = false)
    private LocalDate statDate;

    @Column(name = "reading_minutes", nullable = false)
    private int readingMinutes;

    @Column(name = "lookup_count", nullable = false)
    private int lookupCount;

    @Column(name = "paragraph_translation_count", nullable = false)
    private int paragraphTranslationCount;

    @Column(name = "cards_created", nullable = false)
    private int cardsCreated;

    @Column(name = "cards_reviewed", nullable = false)
    private int cardsReviewed;

    @Column(name = "created_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime updatedAt;

    protected StudyDailyStat() {
    }

    public StudyDailyStat(
            UserAccount user,
            LocalDate statDate,
            int readingMinutes,
            int lookupCount,
            int paragraphTranslationCount,
            int cardsCreated,
            int cardsReviewed) {
        this.user = user;
        this.statDate = statDate;
        this.readingMinutes = readingMinutes;
        this.lookupCount = lookupCount;
        this.paragraphTranslationCount = paragraphTranslationCount;
        this.cardsCreated = cardsCreated;
        this.cardsReviewed = cardsReviewed;
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

    public LocalDate getStatDate() {
        return statDate;
    }

    public int getReadingMinutes() {
        return readingMinutes;
    }

    public int getLookupCount() {
        return lookupCount;
    }

    public int getParagraphTranslationCount() {
        return paragraphTranslationCount;
    }

    public int getCardsCreated() {
        return cardsCreated;
    }

    public int getCardsReviewed() {
        return cardsReviewed;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
