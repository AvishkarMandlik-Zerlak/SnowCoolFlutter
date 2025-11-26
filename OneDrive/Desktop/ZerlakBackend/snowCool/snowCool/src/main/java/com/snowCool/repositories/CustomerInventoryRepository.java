package com.snowCool.repositories;

import com.snowCool.model.CustomerInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerInventoryRepository extends JpaRepository<CustomerInventory, Integer> {
    Optional<CustomerInventory> findByCustomerIdAndGoodsItemId(Integer customerId, Integer goodsItemId);

    // Find all inventory rows for a given customer
    List<CustomerInventory> findByCustomerId(Integer customerId);
}
