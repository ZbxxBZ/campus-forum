package org.example.project.dto.request;

import com.fasterxml.jackson.annotation.JsonAlias;

public record UpdatePostRequest(
        String title,
        String summary,
        String content,
        String format,
        Long boardId,
        String visibility,
        String status,
        String linkUrl,
        String linkTitle,
        String linkSummary,
        Object galleryCaptions,
        Object tags,
        Object attachments,
        @JsonAlias("is_top")
        Boolean isTop,
        @JsonAlias("is_featured")
        Boolean isFeatured
) {
}
