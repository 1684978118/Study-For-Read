package com.studyforread.server.admin;

import com.studyforread.server.admin.dto.AdminLexemeListResponse;
import com.studyforread.server.admin.dto.AdminLexemeRejectResponse;
import com.studyforread.server.admin.dto.AdminLexemeResponse;
import com.studyforread.server.admin.dto.AdminLexemeUpsertRequest;
import com.studyforread.server.vocabulary.Lexeme;
import com.studyforread.server.vocabulary.LexemeEntryType;
import com.studyforread.server.vocabulary.LexemeRepository;
import com.studyforread.server.vocabulary.LexemeStatus;
import java.util.Locale;
import java.util.UUID;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminLexemeService {

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 20;
    private static final int MAX_SIZE = 100;
    private static final String REDACTED_DETAILS_JSON = "{\"redacted\":true}";

    private final ObjectProvider<LexemeRepository> lexemeRepositoryProvider;
    private final ObjectProvider<AdminUserRepository> adminUserRepositoryProvider;
    private final ObjectProvider<AdminAuditLogRepository> adminAuditLogRepositoryProvider;

    public AdminLexemeService(
            ObjectProvider<LexemeRepository> lexemeRepositoryProvider,
            ObjectProvider<AdminUserRepository> adminUserRepositoryProvider,
            ObjectProvider<AdminAuditLogRepository> adminAuditLogRepositoryProvider) {
        this.lexemeRepositoryProvider = lexemeRepositoryProvider;
        this.adminUserRepositoryProvider = adminUserRepositoryProvider;
        this.adminAuditLogRepositoryProvider = adminAuditLogRepositoryProvider;
    }

    @Transactional(readOnly = true)
    public AdminLexemeListResponse list(
            Integer page,
            Integer size,
            String query,
            String sourceLang,
            String targetLang,
            String entryType,
            String status) {
        var pageable = PageRequest.of(
                Math.max(page == null ? DEFAULT_PAGE : page, 0),
                Math.min(Math.max(size == null ? DEFAULT_SIZE : size, 1), MAX_SIZE),
                Sort.by(Sort.Direction.DESC, "createdAt"));
        var lexemes = lexemeRepository().searchForAdmin(
                normalizeBlank(query),
                normalizeBlank(sourceLang),
                normalizeBlank(targetLang),
                parseEntryTypeFilter(entryType),
                parseStatusFilter(status),
                pageable);

        return new AdminLexemeListResponse(
                lexemes.getContent().stream().map(this::toResponse).toList(),
                lexemes.getNumber(),
                lexemes.getSize(),
                lexemes.getTotalElements());
    }

    @Transactional
    public AdminLexemeResponse create(AdminPrincipal principal, AdminLexemeUpsertRequest request) {
        var fields = validatedFields(request);
        ensureNoDuplicate(null, fields.sourceLang(), fields.targetLang(), fields.normalizedSurface(), fields.entryType());

        var lexeme = new Lexeme(
                fields.surface(),
                fields.normalizedSurface(),
                fields.reading(),
                fields.sourceLang(),
                fields.targetLang(),
                fields.entryType(),
                fields.partOfSpeech(),
                fields.definition(),
                fields.shortDefinition(),
                fields.example(),
                fields.status());
        lexeme.assignCreatedByAdminId(principal.id());
        var saved = lexemeRepository().saveAndFlush(lexeme);
        writeAuditLog(principal.id(), "lexeme.create", saved.getId());
        return toResponse(saved);
    }

    @Transactional
    public AdminLexemeResponse update(UUID lexemeId, AdminPrincipal principal, AdminLexemeUpsertRequest request) {
        var lexeme = lexemeRepository().findById(lexemeId).orElseThrow(NotFoundException::new);
        var fields = validatedFields(request);
        ensureNoDuplicate(lexemeId, fields.sourceLang(), fields.targetLang(), fields.normalizedSurface(), fields.entryType());

        lexeme.updatePublicFields(
                fields.surface(),
                fields.normalizedSurface(),
                fields.reading(),
                fields.sourceLang(),
                fields.targetLang(),
                fields.entryType(),
                fields.partOfSpeech(),
                fields.definition(),
                fields.shortDefinition(),
                fields.example(),
                fields.status());
        var saved = lexemeRepository().saveAndFlush(lexeme);
        writeAuditLog(principal.id(), "lexeme.update", saved.getId());
        return toResponse(saved);
    }

    @Transactional
    public AdminLexemeRejectResponse reject(UUID lexemeId, AdminPrincipal principal) {
        var lexeme = lexemeRepository().findById(lexemeId).orElseThrow(NotFoundException::new);
        lexeme.reject();
        var saved = lexemeRepository().saveAndFlush(lexeme);
        writeAuditLog(principal.id(), "lexeme.reject", saved.getId());
        return new AdminLexemeRejectResponse(saved.getId(), saved.getStatus().databaseValue());
    }

    private void ensureNoDuplicate(
            UUID currentLexemeId,
            String sourceLang,
            String targetLang,
            String normalizedSurface,
            LexemeEntryType entryType) {
        lexemeRepository().findBySourceLangAndTargetLangAndNormalizedSurfaceAndEntryType(
                        sourceLang,
                        targetLang,
                        normalizedSurface,
                        entryType.databaseValue())
                .filter(existing -> !existing.getId().equals(currentLexemeId))
                .ifPresent(existing -> {
                    throw new DuplicateLexemeException();
                });
    }

    private LexemeFields validatedFields(AdminLexemeUpsertRequest request) {
        var surface = requireText(request == null ? null : request.surface());
        var definition = requireText(request.definition());
        var sourceLang = requireText(request.sourceLang());
        var targetLang = requireText(request.targetLang());
        var entryType = parseEntryType(request.entryType());
        var status = parseStatus(request.status());

        return new LexemeFields(
                surface,
                normalizeSurface(surface),
                normalizeBlank(request.reading()),
                sourceLang,
                targetLang,
                entryType,
                normalizeBlank(request.partOfSpeech()),
                definition,
                normalizeBlank(request.shortDefinition()),
                normalizeBlank(request.example()),
                status);
    }

    private LexemeEntryType parseEntryType(String value) {
        var normalized = normalizeBlank(value);
        if (normalized == null) {
            throw new InvalidLexemeException();
        }
        try {
            return LexemeEntryType.fromDatabaseValue(normalized);
        } catch (IllegalArgumentException exception) {
            throw new InvalidLexemeException();
        }
    }

    private LexemeStatus parseStatus(String value) {
        var normalized = normalizeBlank(value);
        if (normalized == null) {
            return LexemeStatus.CANDIDATE;
        }
        try {
            return LexemeStatus.fromDatabaseValue(normalized);
        } catch (IllegalArgumentException exception) {
            throw new InvalidLexemeException();
        }
    }

    private String parseEntryTypeFilter(String value) {
        var normalized = normalizeBlank(value);
        if (normalized == null) {
            return null;
        }
        return parseEntryType(normalized).databaseValue();
    }

    private String parseStatusFilter(String value) {
        var normalized = normalizeBlank(value);
        if (normalized == null) {
            return null;
        }
        return parseStatus(normalized).databaseValue();
    }

    private String requireText(String value) {
        var normalized = normalizeBlank(value);
        if (normalized == null) {
            throw new InvalidLexemeException();
        }
        return normalized;
    }

    private String normalizeBlank(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private String normalizeSurface(String surface) {
        return surface.trim().toLowerCase(Locale.ROOT);
    }

    private void writeAuditLog(UUID adminUserId, String action, UUID targetId) {
        var adminUser = adminUserRepository().findById(adminUserId).orElseThrow(AdminRequiredException::new);
        adminAuditLogRepository().save(new AdminAuditLog(
                adminUser,
                action,
                "lexeme",
                targetId,
                REDACTED_DETAILS_JSON,
                null));
    }

    private LexemeRepository lexemeRepository() {
        return lexemeRepositoryProvider.getIfAvailable(() -> {
            throw new AdminRequiredException();
        });
    }

    private AdminUserRepository adminUserRepository() {
        return adminUserRepositoryProvider.getIfAvailable(() -> {
            throw new AdminRequiredException();
        });
    }

    private AdminAuditLogRepository adminAuditLogRepository() {
        return adminAuditLogRepositoryProvider.getIfAvailable(() -> {
            throw new AdminRequiredException();
        });
    }

    private AdminLexemeResponse toResponse(Lexeme lexeme) {
        return new AdminLexemeResponse(
                lexeme.getId(),
                lexeme.getSurface(),
                lexeme.getNormalizedSurface(),
                lexeme.getReading(),
                lexeme.getSourceLang(),
                lexeme.getTargetLang(),
                lexeme.getEntryType().databaseValue(),
                lexeme.getPartOfSpeech(),
                lexeme.getDefinition(),
                lexeme.getShortDefinition(),
                lexeme.getExample(),
                lexeme.getStatus().databaseValue(),
                lexeme.getCreatedAt(),
                lexeme.getUpdatedAt());
    }

    private record LexemeFields(
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
    }

    public static class InvalidLexemeException extends RuntimeException {
    }

    public static class DuplicateLexemeException extends RuntimeException {
    }

    public static class NotFoundException extends RuntimeException {
    }

    public static class AdminRequiredException extends RuntimeException {
    }
}
