package com.studyforread.server.study;

import com.studyforread.server.user.UserAccount;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "translation_events")
public class TranslationEvent {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserAccount user;

    @Column(name = "request_type", nullable = false, length = 32)
    private String requestType;

    @Column(name = "source_lang", nullable = false, length = 16)
    private String sourceLang;

    @Column(name = "target_lang", nullable = false, length = 16)
    private String targetLang;

    @Column(length = 64)
    private String provider;

    @Column(name = "source_text_hash", nullable = false, length = 64, columnDefinition = "char(64)")
    private String sourceTextHash;

    @Column(name = "source_text_length", nullable = false)
    private int sourceTextLength;

    @Column(nullable = false)
    private boolean success;

    @Column(name = "error_code", length = 64)
    private String errorCode;

    @Column(name = "created_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime createdAt;

    protected TranslationEvent() {
    }

    public TranslationEvent(
            UserAccount user,
            TranslationRequestType requestType,
            String sourceLang,
            String targetLang,
            String provider,
            String sourceTextHash,
            int sourceTextLength,
            boolean success,
            String errorCode) {
        this.user = user;
        this.requestType = requestType.databaseValue();
        this.sourceLang = sourceLang;
        this.targetLang = targetLang;
        this.provider = provider;
        this.sourceTextHash = sourceTextHash;
        this.sourceTextLength = sourceTextLength;
        this.success = success;
        this.errorCode = errorCode;
    }

    @PrePersist
    void prePersist() {
        if (id == null) {
            id = UUID.randomUUID();
        }

        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public UserAccount getUser() {
        return user;
    }

    public TranslationRequestType getRequestType() {
        return TranslationRequestType.fromDatabaseValue(requestType);
    }

    public String getSourceLang() {
        return sourceLang;
    }

    public String getTargetLang() {
        return targetLang;
    }

    public String getProvider() {
        return provider;
    }

    public String getSourceTextHash() {
        return sourceTextHash;
    }

    public int getSourceTextLength() {
        return sourceTextLength;
    }

    public boolean isSuccess() {
        return success;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
