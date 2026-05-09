package com.studyforread.server.admin;

import com.studyforread.server.admin.dto.AdminAuditLogListResponse;
import com.studyforread.server.admin.dto.AdminAuditLogResponse;
import com.studyforread.server.admin.dto.AdminPlatformStatsResponse;
import com.studyforread.server.admin.dto.AdminUserListResponse;
import com.studyforread.server.admin.dto.AdminUserSummaryResponse;
import com.studyforread.server.reading.UserBookRepository;
import com.studyforread.server.stats.StudyDailyStatRepository;
import com.studyforread.server.user.UserAccount;
import com.studyforread.server.user.UserAccountRepository;
import com.studyforread.server.user.UserStatus;
import com.studyforread.server.vocabulary.LexemeRepository;
import com.studyforread.server.vocabulary.UserWordCardRepository;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminManagementService {

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_SIZE = 20;
    private static final int MAX_SIZE = 100;

    private final ObjectProvider<UserAccountRepository> userAccountRepositoryProvider;
    private final ObjectProvider<UserBookRepository> userBookRepositoryProvider;
    private final ObjectProvider<LexemeRepository> lexemeRepositoryProvider;
    private final ObjectProvider<UserWordCardRepository> userWordCardRepositoryProvider;
    private final ObjectProvider<StudyDailyStatRepository> studyDailyStatRepositoryProvider;
    private final ObjectProvider<AdminAuditLogRepository> adminAuditLogRepositoryProvider;

    public AdminManagementService(
            ObjectProvider<UserAccountRepository> userAccountRepositoryProvider,
            ObjectProvider<UserBookRepository> userBookRepositoryProvider,
            ObjectProvider<LexemeRepository> lexemeRepositoryProvider,
            ObjectProvider<UserWordCardRepository> userWordCardRepositoryProvider,
            ObjectProvider<StudyDailyStatRepository> studyDailyStatRepositoryProvider,
            ObjectProvider<AdminAuditLogRepository> adminAuditLogRepositoryProvider) {
        this.userAccountRepositoryProvider = userAccountRepositoryProvider;
        this.userBookRepositoryProvider = userBookRepositoryProvider;
        this.lexemeRepositoryProvider = lexemeRepositoryProvider;
        this.userWordCardRepositoryProvider = userWordCardRepositoryProvider;
        this.studyDailyStatRepositoryProvider = studyDailyStatRepositoryProvider;
        this.adminAuditLogRepositoryProvider = adminAuditLogRepositoryProvider;
    }

    @Transactional(readOnly = true)
    public AdminUserListResponse listUsers(Integer page, Integer size, String status, String query) {
        var pageable = pageRequest(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        var normalizedStatus = normalizeUserStatus(status);
        var normalizedQuery = normalizeBlank(query);
        var users = userAccountRepository().searchForAdmin(normalizedStatus, normalizedQuery, pageable);

        return new AdminUserListResponse(
                users.getContent().stream().map(this::toUserSummary).toList(),
                users.getNumber(),
                users.getSize(),
                users.getTotalElements());
    }

    @Transactional(readOnly = true)
    public AdminPlatformStatsResponse getPlatformStats() {
        var totals = studyDailyStatRepository().sumPlatformTotals();

        return new AdminPlatformStatsResponse(
                userAccountRepository().count(),
                userAccountRepository().countByStatus(UserStatus.ACTIVE.databaseValue()),
                userAccountRepository().countByStatus(UserStatus.DISABLED.databaseValue()),
                userBookRepository().count(),
                lexemeRepository().count(),
                userWordCardRepository().count(),
                totals.getReadingMinutes(),
                totals.getLookupCount(),
                totals.getParagraphTranslationCount(),
                totals.getCardsCreated(),
                totals.getCardsReviewed());
    }

    @Transactional(readOnly = true)
    public AdminAuditLogListResponse listAuditLogs(
            Integer page,
            Integer size,
            UUID adminUserId,
            String targetType,
            String action) {
        var pageable = pageRequest(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        var logs = adminAuditLogRepository().searchForAdmin(
                adminUserId,
                normalizeBlank(targetType),
                normalizeBlank(action),
                pageable);

        return new AdminAuditLogListResponse(
                logs.getContent().stream().map(this::toAuditLogResponse).toList(),
                logs.getNumber(),
                logs.getSize(),
                logs.getTotalElements());
    }

    private AdminUserSummaryResponse toUserSummary(UserAccount user) {
        return new AdminUserSummaryResponse(
                user.getId(),
                user.getEmail(),
                user.getDisplayName(),
                user.getSourceLang(),
                user.getTargetLang(),
                user.getStatus().databaseValue(),
                user.getCreatedAt(),
                user.getUpdatedAt());
    }

    private AdminAuditLogResponse toAuditLogResponse(AdminAuditLog log) {
        var adminUser = log.getAdminUser();
        return new AdminAuditLogResponse(
                log.getId(),
                adminUser.getId(),
                adminUser.getUsername(),
                log.getAction(),
                log.getTargetType(),
                log.getTargetId(),
                redactedDetails(),
                log.getCreatedAt());
    }

    private Map<String, Object> redactedDetails() {
        return Map.of("redacted", true);
    }

    private PageRequest pageRequest(Integer page, Integer size, Sort sort) {
        return PageRequest.of(
                Math.max(page == null ? DEFAULT_PAGE : page, 0),
                Math.min(Math.max(size == null ? DEFAULT_SIZE : size, 1), MAX_SIZE),
                sort);
    }

    private String normalizeUserStatus(String status) {
        var normalized = normalizeBlank(status);
        if (normalized == null) {
            return null;
        }
        if (UserStatus.ACTIVE.databaseValue().equals(normalized)
                || UserStatus.DISABLED.databaseValue().equals(normalized)) {
            return normalized;
        }
        return "__invalid_status__";
    }

    private String normalizeBlank(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private UserAccountRepository userAccountRepository() {
        return userAccountRepositoryProvider.getObject();
    }

    private UserBookRepository userBookRepository() {
        return userBookRepositoryProvider.getObject();
    }

    private LexemeRepository lexemeRepository() {
        return lexemeRepositoryProvider.getObject();
    }

    private UserWordCardRepository userWordCardRepository() {
        return userWordCardRepositoryProvider.getObject();
    }

    private StudyDailyStatRepository studyDailyStatRepository() {
        return studyDailyStatRepositoryProvider.getObject();
    }

    private AdminAuditLogRepository adminAuditLogRepository() {
        return adminAuditLogRepositoryProvider.getObject();
    }
}
