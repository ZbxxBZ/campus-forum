package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.PostCommentEntity;

import java.util.List;

@Mapper
public interface PostCommentMapper {
    int insert(PostCommentEntity comment);

    PostCommentEntity findById(@Param("id") Long id);

    List<PostCommentEntity> listByPostId(@Param("postId") Long postId);

    List<PostCommentEntity> listByPostIdPaged(
            @Param("postId") Long postId,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    long countByPostId(@Param("postId") Long postId);

    long countAll();

    List<PostCommentEntity> listByUserId(
            @Param("userId") Long userId,
            @Param("keyword") String keyword,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    long countByUserId(@Param("userId") Long userId, @Param("keyword") String keyword);

    List<Long> listDistinctPostIdsByUserId(@Param("userId") Long userId);
}
