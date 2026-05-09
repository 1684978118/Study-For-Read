package com.studyforread.server.admin;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AdminAuditLogRepository extends JpaRepository<AdminAuditLog, UUID> {

    List<AdminAuditLog> findByAdminUserIdOrderByCreatedAtDesc(UUID adminUserId);
}
