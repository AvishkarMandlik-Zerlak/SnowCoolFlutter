package com.snowCool.controller;

import com.snowCool.config.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.snowCool.config.JwtUtil;

@RestController
@RequestMapping("/api/customer-cylinder-transactions")
public class CustomerCylinderTransactionController {

    @Autowired
    private JwtUtil jwtUtil;

    // Other methods...

    private void someMethod() {
        // Example of replacing static call with instance method
        String token = jwtUtil.generateToken("someUsername", "someRole");
        // ...
    }
}
