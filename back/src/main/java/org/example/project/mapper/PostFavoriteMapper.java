package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PostFavoriteMapper {
    int exists(@Param("postId") Long postId, @Param("userId") Long userId);

    int insert(@Param("postId") Long postId, @Param("userId") Long userId, @Param("createdAt") String createdAt);

    int delete(@Param("postId") Long postId, @Param("userId") Long userId);

    long countByPostId(@Param("postId") Long postId);

    long countAll();

    long countByUserId(@Param("userId") Long userId);

    List<Long> listPostIdsByUserId(
            @Param("userId") Long userId,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    List<Long> listAllPostIdsByUserId(@Param("userId") Long userId);
}
