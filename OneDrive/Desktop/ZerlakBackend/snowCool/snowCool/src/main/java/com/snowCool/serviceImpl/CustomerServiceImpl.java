package com.snowCool.serviceImpl;

import com.snowCool.dto.CustomerDTO;
import com.snowCool.model.ApplicationSettings;
import com.snowCool.model.Challan;
import com.snowCool.model.ChallanType;
import com.snowCool.model.Customer;
import com.snowCool.repositories.ApplicationSettingsRepository;
import com.snowCool.repositories.ChallanRepository;
import com.snowCool.repositories.CustomerRepository;
import com.snowCool.service.ChallanService;
import com.snowCool.service.CustomerService;

import jakarta.transaction.Transactional;

import com.snowCool.exception.CustomException;

import org.hibernate.exception.ConstraintViolationException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class CustomerServiceImpl implements CustomerService {
    @Autowired
    private CustomerRepository customerRepository;
    
    @Autowired 
    private ChallanService challanService;
    
    @Autowired 
    private ChallanRepository challanRepository;
    @Autowired 
    private ApplicationSettingsRepository settingsRepository;
    
    
    
    public Customer dtoToEntity(CustomerDTO dto) {
        Customer c = new Customer();
        c.setName(dto.getName());
        c.setAddress(dto.getAddress());
        c.setContactNumber(dto.getContactNumber());
        c.setEmail(dto.getEmail());
        c.setReminder(dto.getReminder());
        return c;
    }

    public CustomerDTO entityToDto(Customer c) {
        CustomerDTO dto = new CustomerDTO();
        dto.setId(c.getId());      
        dto.setName(c.getName());
        dto.setAddress(c.getAddress());
        dto.setContactNumber(c.getContactNumber());
        dto.setEmail(c.getEmail());
        dto.setReminder(c.getReminder());
        return dto;
    }

    
    private String newChallanNumberFormat(ApplicationSettings settings , ChallanType type )
    {
    	LocalDateTime now = LocalDateTime.now();
    	int year = now.getYear();
    	
    	int startYear ;
    	int endYear;
    	
    	if(now.getMonthValue() < 4)
    	{	
    		startYear = year%100 - 1;
    		endYear = year%100;
    	}
    	else
    	{
    		startYear = year%100 ;
    		endYear = year%100 + 1;
    	}
    	String newChallanNumber = settings.getInvoicePrefix()+"/"+startYear+"-"+endYear+"/"+settings.getChallanSequence();
    	
    	settings.setChallanSequence(settings.getChallanSequence()+1);
    	
    	return newChallanNumber;
    }
    
    @Override
    @Transactional
    public CustomerDTO createCustomer(CustomerDTO customerDTO) {
        Customer customer = dtoToEntity(customerDTO);
      
        try {
        
        	 Customer saved = customerRepository.save(customer);
        	
        if (customerDTO.getItems() != null && !customerDTO.getItems().isEmpty())
        {
	        Challan challan = new Challan();
	        challan.setCustomer(customer);
	        challan.setItems(challanService.dtoItemsToEntities(customerDTO.getItems() , challan));
	        challan.setChallanNumber(newChallanNumberFormat(settingsRepository.findById(1).get(), ChallanType.RECEIVED));
	        challan.setSiteLocation(customerDTO.getAddress());
	        challan.setDeposite(customerDTO.getDeposite());
	        challanRepository.save(challan);
        }
        	return entityToDto(saved);
        }
        catch (DataIntegrityViolationException e) {
			
        	Throwable rootCause = e.getCause();
        	
        	if(rootCause instanceof  ConstraintViolationException cvex)
        	{
        		if(cvex.getConstraintName() != null)
        		{
        			if(cvex.getConstraintName().contains("contact_number"))
        			{
        				throw new CustomException("Customer with this contact number already exists", HttpStatus.BAD_REQUEST);
        			}
        			if(cvex.getConstraintName().contains("email"))
        			{
        				throw new CustomException("Customer With this Email Already Exists",HttpStatus.BAD_REQUEST);
        			}
        		}
        	}

        	throw new CustomException("Customer with this Details already exists", HttpStatus.BAD_REQUEST);
		}
       
    }

    @Override
    public CustomerDTO  getCustomerById(int id) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new CustomException("Customer not found with id: " + id,HttpStatus.NOT_FOUND));
        return entityToDto(customer);
    }

    @Override
    public List<CustomerDTO> getAllCustomers() {
        return customerRepository.findAll().stream()
                .map(this::entityToDto)
                .collect(Collectors.toList());
    }

    @Override
    public ResponseEntity<String> updateCustomer(int id, CustomerDTO customerDTO) {
        Customer existing = customerRepository.findById(id)
                .orElseThrow(() -> new CustomException("Customer not found with id: " + id,HttpStatus.NOT_FOUND));

        if (!customerDTO.getName().equals(existing.getName())) {
            existing.setName(customerDTO.getName());
        }

        if (!customerDTO.getAddress().equals(existing.getAddress())) {
            existing.setAddress(customerDTO.getAddress());
        }

        if (!customerDTO.getContactNumber().equals(existing.getContactNumber())) {
            existing.setContactNumber(customerDTO.getContactNumber());
        }

        if (!customerDTO.getEmail().equals(existing.getEmail())) {
            existing.setEmail(customerDTO.getEmail());
        }

        Customer updated = customerRepository.save(existing);
        return new ResponseEntity<String>("Customer with id : " + existing.getId() + " Updated Successfully" , HttpStatus.OK);
    }


    @Override
    public void deleteCustomer(int id) {
        Customer existing = customerRepository.findById(id)
                .orElseThrow(() -> new CustomException("Customer not found with id: " + id,HttpStatus.NOT_FOUND));
        customerRepository.delete(existing);
    }

    @Override
    public Page<CustomerDTO> getCustomersPage(Pageable pageable) {
        return customerRepository.findAll(pageable)
            .map(this::entityToDto);
    }

    @Override
    public List<CustomerDTO> search(String name, String contactNumber, String email) {
        return customerRepository.search(name, contactNumber, email)
            .stream()
            .map(this::entityToDto)
            .collect(java.util.stream.Collectors.toList());
    }
    
   
}
