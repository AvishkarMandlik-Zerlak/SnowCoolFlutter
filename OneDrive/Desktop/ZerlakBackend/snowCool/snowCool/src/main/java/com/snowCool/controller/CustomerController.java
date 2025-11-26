package com.snowCool.controller;

import com.snowCool.dto.CustomerDTO;
import com.snowCool.service.CustomerService;
import com.snowCool.util.AccessControlUtil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.server.ResponseStatusException;
import com.snowCool.config.JwtUtil;
import com.snowCool.repositories.UserRepository;
import com.snowCool.model.User;

import java.util.List;

@RestController
@RequestMapping("/api/v1/customers")
public class CustomerController {
    @Autowired
    private CustomerService customerService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtUtil jwtUtil;

    private User extractUser(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing or invalid Authorization header");
        }
        String token = authHeader.substring(7);
        try {
            String username = jwtUtil.getUsernameFromToken(token);
            User user = userRepository.findByUsername(username);
            if (user == null) throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid token user");
            if (user.getActive() != null && !user.getActive()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Account disabled");
            }
            return user;
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid token");
        }
    }

//    private boolean isAdmin(User user) {
//        String role = user.getRole();
//        return role != null && "ADMIN".equalsIgnoreCase(role.trim());
//    }
    
    private void assertChallanAccess(User user) {
        if (!AccessControlUtil.hasPermission(user, user.getCanCreateCustomer())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied: challan management not permitted");
        }
    }

    @PostMapping("/save")
    public CustomerDTO createCustomer(@RequestBody CustomerDTO customerDTO,
                                      @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
        assertChallanAccess(user);
        return customerService.createCustomer(customerDTO);
    }

    @GetMapping("/getById/{id}")
    public CustomerDTO getCustomerById(@PathVariable int id,
                                       @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
        assertChallanAccess(user);
        return customerService.getCustomerById(id);
    }

    @GetMapping("/getAllCustomers")
    public List<CustomerDTO> getAllCustomers(@RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
        assertChallanAccess(user);
        return customerService.getAllCustomers();
    }

    @GetMapping("/page")
    public Page<CustomerDTO> getCustomersPage(@RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "10") int size,
                                              @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
        assertChallanAccess(user);
        return customerService.getCustomersPage(PageRequest.of(page, size));
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<String> updateCustomer(@PathVariable int id, @RequestBody CustomerDTO customerDTO,
                                      @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
        assertChallanAccess(user);
        return customerService.updateCustomer(id, customerDTO);
    }

    @DeleteMapping("/deleteById/{id}")
    public void deleteCustomer(@PathVariable int id,
                               @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
        assertChallanAccess(user);
        customerService.deleteCustomer(id);
    }

    @GetMapping("/search")
    public List<CustomerDTO> search(@RequestParam(required = false) String name,
                                    @RequestParam(required = false) String contactNumber,
                                    @RequestParam(required = false) String email,
                                    @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
        assertChallanAccess(user);
        return customerService.search(name, contactNumber, email);
    }
    	
}
