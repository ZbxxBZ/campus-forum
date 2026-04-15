package org.example.project.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.project.model.BoardEntity;

import java.util.List;

@Mapper
public interface BoardMapper {
    int insert(BoardEntity board);

    int updateSelective(BoardEntity board);

    BoardEntity findById(@Param("id") Long id);

    BoardEntity findByCode(@Param("code") String code);

    List<BoardEntity> list(@Param("keyword") String keyword, @Param("status") String status);

    List<BoardEntity> listAvailable();

    long count(@Param("keyword") String keyword, @Param("status") String status);
}
