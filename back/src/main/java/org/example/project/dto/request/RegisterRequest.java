package org.example.project.dto.request;

public record RegisterRequest(
        String username,
        String displayName,
        String email,
        String password
) {
}
