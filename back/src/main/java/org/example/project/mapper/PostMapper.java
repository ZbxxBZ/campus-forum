package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.PostEntity;

import java.util.List;
import java.util.Map;

@Mapper
public interface PostMapper {
    int insert(PostEntity post);

    int updateSelective(PostEntity post);

    List<PostEntity> list(
            @Param("keyword") String keyword,
            @Param("status") String status,
            @Param("statuses") List<String> statuses,
            @Param("boardId") Long boardId,
            @Param("format") String format,
            @Param("visibility") String visibility,
            @Param("author") String author,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    long count(
            @Param("keyword") String keyword,
            @Param("status") String status,
            @Param("statuses") List<String> statuses,
            @Param("boardId") Long boardId,
            @Param("format") String format,
            @Param("visibility") String visibility,
            @Param("author") String author
    );

    List<PostEntity> listPublished(
            @Param("feed") String feed,
            @Param("requesterUserId") Long requesterUserId,
            @Param("keywordTerms") List<String> keywordTerms,
            @Param("preferredTags") List<String> preferredTags,
            @Param("author") String author,
            @Param("tag") String tag,
            @Param("boardId") Long boardId,
            @Param("format") String format,
            @Param("dateFrom") String dateFrom,
            @Param("dateTo") String dateTo,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    List<PostEntity> listPendingReview(
            @Param("keyword") String keyword,
            @Param("boardId") Long boardId,
            @Param("format") String format,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    long countPendingReview(
            @Param("keyword") String keyword,
            @Param("boardId") Long boardId,
            @Param("format") String format
    );

    long countPublished(
            @Param("feed") String feed,
            @Param("requesterUserId") Long requesterUserId,
            @Param("keywordTerms") List<String> keywordTerms,
            @Param("author") String author,
            @Param("tag") String tag,
            @Param("boardId") Long boardId,
            @Param("format") String format,
            @Param("dateFrom") String dateFrom,
            @Param("dateTo") String dateTo
    );

    PostEntity findById(@Param("id") Long id);

    int updateBoardNameByBoardId(@Param("boardId") Long boardId, @Param("boardName") String boardName);

    int updateReview(@Param("postId") Long postId, @Param("status") String status, @Param("riskLevel") String riskLevel);

    long countAll();

    long countByStatus(@Param("status") String status);

    long countByStatusAndUpdatedDatePrefix(@Param("status") String status, @Param("datePrefix") String datePrefix);

    List<Map<String, Object>> countCreatedTrendByDate(@Param("dateFrom") String dateFrom, @Param("dateTo") String dateTo);

    List<Map<String, Object>> countBoardDistributionTop(@Param("limit") int limit);
}
