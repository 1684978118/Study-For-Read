package com.studyforread.server.reading;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserBookRepository extends JpaRepository<UserBook, UUID> {

    Optional<UserBook> findByUserIdAndBookFingerprint(UUID userId, String bookFingerprint);

    List<UserBook> findByUserIdOrderByLastReadAtDesc(UUID userId);
}
