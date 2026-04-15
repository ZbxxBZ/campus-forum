package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.AuditLogEntity;

import java.util.List;

@Mapper
public interface AuditLogMapper {
    int insert(AuditLogEntity entity);

    List<AuditLogEntity> list(
            @Param("keyword") String keyword,
            @Param("action") String action,
            @Param("role") String role,
            @Param("operator") String operator,
            @Param("offset") int offset,
            @Param("pageSize") int pageSize
    );

    long count(
            @Param("keyword") String keyword,
            @Param("action") String action,
            @Param("role") String role,
            @Param("operator") String operator
    );
}
