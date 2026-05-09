package com.studyforread.server.security;

import com.studyforread.server.admin.AdminAuthService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class AdminAuthenticationFilter extends OncePerRequestFilter {

    private final AdminJwtService adminJwtService;
    private final AdminAuthService adminAuthService;

    public AdminAuthenticationFilter(AdminJwtService adminJwtService, AdminAuthService adminAuthService) {
        this.adminJwtService = adminJwtService;
        this.adminAuthService = adminAuthService;
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
            adminJwtService.parseAccessToken(authorizationHeader.substring("Bearer ".length()))
                    .flatMap(subject -> {
                        try {
                            return java.util.Optional.of(adminAuthService.activePrincipal(subject.adminId()));
                        } catch (AdminAuthService.AdminRequiredException exception) {
                            return java.util.Optional.empty();
                        }
                    })
                    .ifPresent(principal -> SecurityContextHolder.getContext().setAuthentication(
                            new UsernamePasswordAuthenticationToken(
                                    principal,
                                    null,
                                    List.of(new SimpleGrantedAuthority("ROLE_ADMIN")))));
        }

        filterChain.doFilter(request, response);
    }
}
