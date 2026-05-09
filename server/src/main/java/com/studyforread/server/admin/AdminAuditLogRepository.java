package com.studyforread.server.admin;

import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AdminAuditLogRepository extends JpaRepository<AdminAuditLog, UUID> {

    List<AdminAuditLog> findByAdminUserIdOrderByCreatedAtDesc(UUID adminUserId);

    @EntityGraph(attributePaths = "adminUser")
    @Query("""
            select log
            from AdminAuditLog log
            where (:adminUserId is null or log.adminUser.id = :adminUserId)
              and (:targetType is null or log.targetType = :targetType)
              and (:action is null or log.action = :action)
            """)
    Page<AdminAuditLog> searchForAdmin(
            @Param("adminUserId") UUID adminUserId,
            @Param("targetType") String targetType,
            @Param("action") String action,
            Pageable pageable);
}
