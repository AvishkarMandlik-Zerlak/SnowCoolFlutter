package com.snowCool.repositories;

import com.snowCool.model.Challan;
import com.snowCool.model.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Integer> {
    @Query("SELECT c FROM Customer c WHERE (:name IS NULL OR c.name LIKE %:name%) AND (:contactNumber IS NULL OR c.contactNumber LIKE %:contactNumber%) AND (:email IS NULL OR c.email LIKE %:email%)")
    List<Customer> search(@Param("name") String name, @Param("contactNumber") String contactNumber, @Param("email") String email);
    
    @Query("SELECT c FROM Customer c WHERE c.name = :name")
    Optional<Customer> findByName(String name);
   
    
}
