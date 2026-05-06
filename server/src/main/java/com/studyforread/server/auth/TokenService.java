package com.studyforread.server.auth;

import com.studyforread.server.user.UserAccount;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.Base64;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.stereotype.Service;

@Service
public class TokenService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final char[] HEX = "0123456789abcdef".toCharArray();
    private final SecureRandom secureRandom = new SecureRandom();
    private final byte[] signingKey = randomBytes(32);

    public String createAccessToken(UserAccount user) {
        var payload = "%s:%s:%d".formatted(
                user.getId(),
                user.getEmail(),
                OffsetDateTime.now().plusMinutes(15).toEpochSecond());
        var encodedPayload = base64Url(payload.getBytes(StandardCharsets.UTF_8));
        return "access." + encodedPayload + "." + sign(encodedPayload);
    }

    public String createRefreshToken() {
        return "refresh." + base64Url(randomBytes(32));
    }

    public String sha256Hex(String token) {
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            return hex(digest.digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to hash token", exception);
        }
    }

    public OffsetDateTime refreshTokenExpiresAt() {
        return OffsetDateTime.now().plusDays(30);
    }

    private String sign(String payload) {
        try {
            var mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(signingKey, HMAC_ALGORITHM));
            return base64Url(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to sign access token", exception);
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

    private String hex(byte[] bytes) {
        var result = new char[bytes.length * 2];
        for (var index = 0; index < bytes.length; index++) {
            var value = bytes[index] & 0xff;
            result[index * 2] = HEX[value >>> 4];
            result[index * 2 + 1] = HEX[value & 0x0f];
        }
        return new String(result);
    }
}
