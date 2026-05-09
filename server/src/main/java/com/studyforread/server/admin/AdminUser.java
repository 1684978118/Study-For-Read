package com.studyforread.server.admin;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "admin_users")
public class AdminUser {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(nullable = false, unique = true, length = 80)
    private String username;

    @Column(name = "credential_hash", nullable = false, length = 255)
    private String credentialHash;

    @Column(nullable = false, length = 32)
    private String role;

    @Column(nullable = false, length = 32)
    private String status;

    @Column(name = "created_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false, columnDefinition = "timestamp with time zone")
    private OffsetDateTime updatedAt;

    protected AdminUser() {
    }

    public AdminUser(String username, String credentialHash, AdminRole role, AdminStatus status) {
        this.username = username;
        this.credentialHash = credentialHash;
        this.role = role.databaseValue();
        this.status = status.databaseValue();
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

    public String getUsername() {
        return username;
    }

    public String getCredentialHash() {
        return credentialHash;
    }

    public AdminRole getRole() {
        return AdminRole.fromDatabaseValue(role);
    }

    public AdminStatus getStatus() {
        return AdminStatus.fromDatabaseValue(status);
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
