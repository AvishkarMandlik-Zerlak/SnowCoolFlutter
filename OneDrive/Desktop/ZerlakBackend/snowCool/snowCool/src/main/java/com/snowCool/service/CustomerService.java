package com.snowCool.service;

import com.snowCool.dto.CustomerDTO;
import com.snowCool.model.Customer;

import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;

public interface CustomerService {
    CustomerDTO createCustomer(CustomerDTO customerDTO);
    CustomerDTO getCustomerById(int id);
    List<CustomerDTO> getAllCustomers();
    ResponseEntity<String> updateCustomer(int id, CustomerDTO customerDTO);
    void deleteCustomer(int id);
    Page<CustomerDTO> getCustomersPage(Pageable pageable);
    List<CustomerDTO> search(String name, String contactNumber, String email);
    
}
