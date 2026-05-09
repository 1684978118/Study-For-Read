package com.studyforread.server.user;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserAccountRepository extends JpaRepository<UserAccount, UUID> {

    Optional<UserAccount> findByEmail(String email);

    long countByStatus(String status);

    @Query("""
            select user
            from UserAccount user
            where (:status is null or user.status = :status)
              and (
                :query is null
                or lower(user.email) like lower(concat('%', :query, '%'))
                or lower(coalesce(user.displayName, '')) like lower(concat('%', :query, '%'))
              )
            """)
    Page<UserAccount> searchForAdmin(
            @Param("status") String status,
            @Param("query") String query,
            Pageable pageable);
}
