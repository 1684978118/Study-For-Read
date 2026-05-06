package com.studyforread.server.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.studyforread.server.api.ApiResponse;
import com.studyforread.server.api.ErrorCode;
import com.studyforread.server.auth.TokenService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.filter.OncePerRequestFilter;

@Configuration
public class SecurityConfig {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, TokenService tokenService) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .exceptionHandling(exceptionHandling -> exceptionHandling.authenticationEntryPoint((request, response, exception) -> {
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    OBJECT_MAPPER.writeValue(response.getOutputStream(),
                            ApiResponse.fail(ErrorCode.UNAUTHORIZED, "Unauthorized"));
                }))
                .authorizeHttpRequests(authorize -> authorize
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/register").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/login").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/refresh").permitAll()
                        .anyRequest().authenticated())
                .addFilterBefore(new BearerAccessTokenFilter(tokenService), UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    private static class BearerAccessTokenFilter extends OncePerRequestFilter {

        private final TokenService tokenService;

        BearerAccessTokenFilter(TokenService tokenService) {
            this.tokenService = tokenService;
        }

        @Override
        protected void doFilterInternal(
                HttpServletRequest request,
                HttpServletResponse response,
                FilterChain filterChain) throws ServletException, IOException {
            var authorizationHeader = request.getHeader("Authorization");
            if (authorizationHeader != null
                    && authorizationHeader.startsWith("Bearer ")
                    && SecurityContextHolder.getContext().getAuthentication() == null) {
                tokenService.parseAccessToken(authorizationHeader.substring("Bearer ".length()))
                        .ifPresent(subject -> SecurityContextHolder.getContext().setAuthentication(
                                new UsernamePasswordAuthenticationToken(
                                        subject.userId().toString(),
                                        null,
                                        List.of(new SimpleGrantedAuthority("ROLE_USER")))));
            }

            filterChain.doFilter(request, response);
        }
    }
}
