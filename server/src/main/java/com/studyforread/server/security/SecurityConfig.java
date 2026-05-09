package com.studyforread.server.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
class AdminSecurityConfig {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    @Bean
    @Order(1)
    SecurityFilterChain adminSecurityFilterChain(
            HttpSecurity http,
            AdminAuthenticationFilter adminAuthenticationFilter) throws Exception {
        return http
                .securityMatcher("/api/v1/admin/**")
                .csrf(AbstractHttpConfigurer::disable)
                .exceptionHandling(exceptionHandling -> exceptionHandling.authenticationEntryPoint((request, response, exception) -> {
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    OBJECT_MAPPER.writeValue(response.getOutputStream(),
                            ApiResponse.fail(ErrorCode.ADMIN_REQUIRED, "Admin authentication required"));
                }))
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers(HttpMethod.POST, "/api/v1/admin/auth/login").permitAll()
                        .anyRequest().authenticated())
                .addFilterBefore(adminAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }
}
