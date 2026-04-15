package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

@Mapper
public interface AuthTokenMapper {
    int insert(@Param("token") String token, @Param("userId") Long userId, @Param("lastSeen") String lastSeen);

    Long findUserIdByToken(@Param("token") String token);

    int touch(@Param("token") String token, @Param("lastSeen") String lastSeen);

    long countOnlineUsersSince(@Param("since") String since);

    List<Map<String, Object>> countActiveTrendByDate(@Param("dateFrom") String dateFrom, @Param("dateTo") String dateTo);
}
