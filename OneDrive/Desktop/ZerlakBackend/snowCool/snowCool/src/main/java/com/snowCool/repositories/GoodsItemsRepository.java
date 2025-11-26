package com.snowCool.repositories;


import com.snowCool.model.GoodsItems;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface GoodsItemsRepository extends JpaRepository<GoodsItems , Integer> {
    Optional<GoodsItems> findByNameIgnoreCase(String name);
    boolean existsByNameIgnoreCase(String name);
}
