package com.studyforread.server.vocabulary;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "lexemes")
public class Lexeme {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(nullable = false, length = 255)
    private String surface;

    @Column(name = "normalized_surface", nullable = false, length = 255)
    private String normalizedSurface;

    @Column(length = 255)
    private String reading;

    @Column(name = "source_lang", nullable = false, length = 16)
    private String sourceLang;

    @Column(name = "target_lang", nullable = false, length = 16)
    private String targetLang;

    @Column(name = "entry_type", nullable = false, length = 32)
    private String entryType;

    @Column(name = "part_of_speech", length = 64)
    private String partOfSpeech;

    @Column(nullable = false, columnDefinition = "text")
    private String definition;

    @Column(name = "short_definition", length = 500)
    private String shortDefinition;

    @Column(columnDefinition = "text")
    private String example;

    @Column(nullable = false, length = 32)
    private String status;

    @Column(name = "created_by_admin_id")
    private UUID createdByAdminId;

    @Column(name = "created_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime updatedAt;

    protected Lexeme() {
    }

    public Lexeme(
            String surface,
            String normalizedSurface,
            String reading,
            String sourceLang,
            String targetLang,
            LexemeEntryType entryType,
            String partOfSpeech,
            String definition,
            String shortDefinition,
            String example,
            LexemeStatus status) {
        this.surface = surface;
        this.normalizedSurface = normalizedSurface;
        this.reading = reading;
        this.sourceLang = sourceLang;
        this.targetLang = targetLang;
        this.entryType = entryType.databaseValue();
        this.partOfSpeech = partOfSpeech;
        this.definition = definition;
        this.shortDefinition = shortDefinition;
        this.example = example;
        this.status = status.databaseValue();
    }

    public void assignCreatedByAdminId(UUID createdByAdminId) {
        this.createdByAdminId = createdByAdminId;
    }

    public void updatePublicFields(
            String surface,
            String normalizedSurface,
            String reading,
            String sourceLang,
            String targetLang,
            LexemeEntryType entryType,
            String partOfSpeech,
            String definition,
            String shortDefinition,
            String example,
            LexemeStatus status) {
        this.surface = surface;
        this.normalizedSurface = normalizedSurface;
        this.reading = reading;
        this.sourceLang = sourceLang;
        this.targetLang = targetLang;
        this.entryType = entryType.databaseValue();
        this.partOfSpeech = partOfSpeech;
        this.definition = definition;
        this.shortDefinition = shortDefinition;
        this.example = example;
        this.status = status.databaseValue();
    }

    public void reject() {
        this.status = LexemeStatus.REJECTED.databaseValue();
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

    public String getSurface() {
        return surface;
    }

    public String getNormalizedSurface() {
        return normalizedSurface;
    }

    public String getReading() {
        return reading;
    }

    public String getSourceLang() {
        return sourceLang;
    }

    public String getTargetLang() {
        return targetLang;
    }

    public LexemeEntryType getEntryType() {
        return LexemeEntryType.fromDatabaseValue(entryType);
    }

    public String getPartOfSpeech() {
        return partOfSpeech;
    }

    public String getDefinition() {
        return definition;
    }

    public String getShortDefinition() {
        return shortDefinition;
    }

    public String getExample() {
        return example;
    }

    public LexemeStatus getStatus() {
        return LexemeStatus.fromDatabaseValue(status);
    }

    public UUID getCreatedByAdminId() {
        return createdByAdminId;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
