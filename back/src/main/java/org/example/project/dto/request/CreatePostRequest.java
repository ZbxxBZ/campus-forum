package org.example.project.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;

public record CreatePostRequest(
        String title,
        String summary,
        String content,
        String format,
        Object attachments,
        Object tags,
        Long boardId,
        String visibility,
        String status,
        String linkUrl,
        String linkTitle,
        String linkSummary,
        Object galleryCaptions,
        @JsonAlias("is_top")
        Boolean isTop,
        @JsonAlias("is_featured")
        Boolean isFeatured,
        String author
) {
}
