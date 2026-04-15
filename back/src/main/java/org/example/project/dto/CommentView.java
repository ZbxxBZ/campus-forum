package org.example.project.dto;

import org.example.project.model.PostCommentEntity;

public record CommentView(
        Long id,
        Long postId,
        String postTitle,
        Long parentId,
        String author,
        Long authorId,
        String content,
        String createdAt
) {
    public static CommentView from(PostCommentEntity entity) {
        return new CommentView(
                entity.getId(),
                entity.getPostId(),
                entity.getPostTitle(),
                entity.getParentId(),
                entity.getAuthor(),
                entity.getUserId(),
                entity.getContent(),
                entity.getCreatedAt()
        );
    }
}
