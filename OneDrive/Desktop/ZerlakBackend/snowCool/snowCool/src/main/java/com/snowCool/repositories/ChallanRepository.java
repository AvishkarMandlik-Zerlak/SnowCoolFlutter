package com.snowCool.repositories;

import com.snowCool.dto.ChallanDTO;
import com.snowCool.model.Challan;
import com.snowCool.model.Customer;

import jakarta.transaction.Transactional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChallanRepository extends JpaRepository<Challan, Integer> {
    @Query("SELECT DISTINCT c FROM Challan c LEFT JOIN FETCH c.items")
    List<Challan> findAllWithItems();

//    @Query("SELECT c FROM Challan c LEFT JOIN FETCH c.items WHERE c.id = :id")
//    Challan findByIdWithItems(@Param("id") int id);
    
 // In ChallanRepository
    @Query("SELECT c FROM Challan c LEFT JOIN FETCH c.items WHERE c.id = :id")
    Optional<Challan> findByIdWithItems(@Param("id") Integer id);
    
    
    @Modifying
    @Transactional
    @Query("DELETE FROM ChallanItem ci WHERE ci.challan.id IN :ids")
    int deleteItemsByChallanIds(@Param("ids") List<Integer> ids);

    @Modifying 
    @Transactional
    @Query("DELETE FROM Challan c WHERE c.id IN :ids")
    int deleteChallansByIds(@Param("ids") List<Integer> ids);
    
    @Query("SELECT ch.challanNumber FROM Challan ch " +
 	       "INNER JOIN ch.customer c " +
 	       "WHERE c.id = :id and ch.challanType = 'DELIVERED'")
 	List<String> findChallanByCustomerId(@Param("id") int id);
    
    
    @Query("SELECT c FROM Challan c LEFT JOIN FETCH c.items WHERE c.challanNumber = :challanNumber")
    Optional<Challan> findChallanByChallanNumberWithItems(@Param("challanNumber") String challanNumber);
    
    @Modifying
    @Query("UPDATE Challan c SET c.returnedAmount = c.returnedAmount + :returnedAmount WHERE c.challanNumber = :deliveredChallanNo AND c.challanType = 'DELIVERED'")
    int updateDeliveryReturnedAmount(@Param("deliveredChallanNo") String deliveredChallanNo,@Param("returnedAmount") double returnedAmount);
 
    Challan findChallanByChallanNumber(@Param("challanNumber") String challanNumber);
    
	@Modifying
	@Transactional
	@Query("UPDATE ChallanItem ci " +
	        "SET ci.receivedQty = ci.receivedQty + :qty " +
	        "WHERE ci.id = :itemId " +
	        "  AND ci.receivedQty + :qty <= ci.deliveredQty")
	int incrementReceivedQty( @Param("itemId") int itemId,@Param("qty") int qty);
    
    
    @Query("SELECT c FROM Challan c WHERE (:name IS NULL OR LOWER(c.customer.name) LIKE LOWER(CONCAT('%', :name, '%'))) AND (:contactNumber IS NULL OR c.customer.contactNumber LIKE %:contactNumber%) AND (:email IS NULL OR LOWER(c.customer.email) LIKE LOWER(CONCAT('%', :email, '%')))")
    List<Challan> searchChallans(@Param("name") String name, @Param("contactNumber") String contactNumber,@Param("email") String email);
    
   
}