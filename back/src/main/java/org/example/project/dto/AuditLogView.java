package org.example.project.dto;

import org.example.project.model.AuditLogEntity;

public record AuditLogView(
        Long id,
        String action,
        String actionLabel,
        Long postId,
        String postTitle,
        Long operatorId,
        String operator,
        String operatorRole,
        String detail,
        String createdAt
) {
    public static AuditLogView from(AuditLogEntity entity) {
        return new AuditLogView(
                entity.getId(),
                entity.getAction(),
                entity.getActionLabel(),
                entity.getPostId(),
                entity.getPostTitle(),
                entity.getOperatorId(),
                entity.getOperator(),
                entity.getOperatorRole(),
                entity.getDetail(),
                entity.getCreatedAt()
        );
    }
}
