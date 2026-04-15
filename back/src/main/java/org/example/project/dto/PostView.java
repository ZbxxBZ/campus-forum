package org.example.project.dto;

import org.example.project.model.PostEntity;

import java.util.List;

public record PostView(
        Long id,
        String title,
        String summary,
        String content,
        String format,
        String formatLabel,
        List<String> attachments,
        List<String> tags,
        List<String> galleryCaptions,
        String linkUrl,
        String linkTitle,
        String linkSummary,
        Long boardId,
        String boardName,
        String author,
        Long authorId,
        String authorAvatar,
        String visibility,
        String status,
        String riskLevel,
        Boolean isTop,
        Boolean isFeatured,
        String createdAt,
        String updatedAt,
        Long likeCount,
        Long favoriteCount,
        Long commentCount,
        Long hotScore
) {
    public static PostView from(
            PostEntity post,
            List<String> attachments,
            List<String> tags,
            List<String> galleryCaptions,
            String authorName,
            Long authorId,
            String authorAvatar,
            Long likeCount,
            Long favoriteCount,
            Long commentCount,
            Long hotScore
    ) {
        return new PostView(
                post.getId(),
                post.getTitle(),
                post.getSummary(),
                post.getContent(),
                post.getFormat(),
                toChinesePostFormat(post.getFormat()),
                attachments,
                tags,
                galleryCaptions,
                post.getLinkUrl(),
                post.getLinkTitle(),
                post.getLinkSummary(),
                post.getBoardId(),
                post.getBoardName(),
                authorName,
                authorId,
                authorAvatar,
                post.getVisibility(),
                post.getStatus(),
                post.getRiskLevel(),
                post.getIsTop(),
                post.getIsFeatured(),
                post.getCreatedAt(),
                post.getUpdatedAt(),
                likeCount,
                favoriteCount,
                commentCount,
                hotScore
        );
    }

    private static String toChinesePostFormat(String format) {
        if (format == null) {
            return null;
        }
        return switch (format) {
            case "rich_text" -> "富文本";
            case "markdown" -> "Markdown";
            case "image_gallery" -> "图文相册";
            case "external_link" -> "外链分享";
            default -> format;
        };
    }
}
