package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.dto.FollowUserView;

import java.util.List;

@Mapper
public interface UserFollowMapper {
    int exists(@Param("userId") Long userId, @Param("targetUserId") Long targetUserId);

    int insert(@Param("userId") Long userId, @Param("targetUserId") Long targetUserId, @Param("createdAt") String createdAt);

    int delete(@Param("userId") Long userId, @Param("targetUserId") Long targetUserId);

    List<FollowUserView> listFollowing(
            @Param("userId") Long userId,
            @Param("keyword") String keyword,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    long countFollowing(@Param("userId") Long userId, @Param("keyword") String keyword);

    long countFollowerByTargetUserId(@Param("targetUserId") Long targetUserId);
}
