package com.studyforread.server.security;

import com.studyforread.server.admin.AdminUser;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.stereotype.Service;

@Service
public class AdminJwtService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private final SecureRandom secureRandom = new SecureRandom();
    private final byte[] signingKey = randomBytes(32);

    public String createAccessToken(AdminUser adminUser) {
        var payload = "admin:%s:%s:%s:%d".formatted(
                adminUser.getId(),
                adminUser.getUsername(),
                adminUser.getRole().databaseValue(),
                OffsetDateTime.now().plusMinutes(15).toEpochSecond());
        var encodedPayload = base64Url(payload.getBytes(StandardCharsets.UTF_8));
        return "admin_access." + encodedPayload + "." + sign(encodedPayload);
    }

    public Optional<AdminTokenSubject> parseAccessToken(String accessToken) {
        var parts = accessToken.split("\\.", -1);
        if (parts.length != 3 || !"admin_access".equals(parts[0]) || !MessageDigest.isEqual(
                sign(parts[1]).getBytes(StandardCharsets.UTF_8),
                parts[2].getBytes(StandardCharsets.UTF_8))) {
            return Optional.empty();
        }

        try {
            var payload = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8);
            var payloadParts = payload.split(":", -1);
            if (payloadParts.length != 5 || !"admin".equals(payloadParts[0])) {
                return Optional.empty();
            }

            var expiresAtEpochSecond = Long.parseLong(payloadParts[4]);
            if (expiresAtEpochSecond <= OffsetDateTime.now().toEpochSecond()) {
                return Optional.empty();
            }

            return Optional.of(new AdminTokenSubject(
                    UUID.fromString(payloadParts[1]),
                    payloadParts[2],
                    payloadParts[3]));
        } catch (IllegalArgumentException exception) {
            return Optional.empty();
        }
    }

    private String sign(String payload) {
        try {
            var mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(signingKey, HMAC_ALGORITHM));
            return base64Url(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to sign admin access token", exception);
        }
    }

    private byte[] randomBytes(int size) {
        var bytes = new byte[size];
        secureRandom.nextBytes(bytes);
        return bytes;
    }

    private String base64Url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public record AdminTokenSubject(UUID adminId, String username, String role) {
    }
}
