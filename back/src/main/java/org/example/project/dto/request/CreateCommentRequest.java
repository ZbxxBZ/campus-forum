package org.example.project.dto.request;

public record CreateCommentRequest(
        Long parentId,
        String content,
        String author
) {
}

