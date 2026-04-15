package org.example.project.dto;

import org.example.project.model.UserEntity;

public record UserView(
        Long id,
        String username,
        String displayName,
        String email,
        String role,
        String status,
        String createdAt
) {
    public static UserView from(UserEntity user) {
        return new UserView(
                user.getId(),
                user.getUsername(),
                user.getDisplayName(),
                user.getEmail(),
                user.getRole(),
                user.getStatus(),
                user.getCreatedAt()
        );
    }
}
