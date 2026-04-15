package org.example.project.dto;

public record FollowUserView(
        Long id,
        String username,
        String displayName,
        String avatar,
        String role,
        String bio,
        String joinedAt
) {
}
