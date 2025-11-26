package com.snowCool.controller;

import com.snowCool.dto.ApplicationSettingsDTO;
import com.snowCool.model.User;
import com.snowCool.repositories.UserRepository;
import com.snowCool.service.ApplicationSettingsService;
import com.snowCool.util.AccessControlUtil;
import com.snowCool.config.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/settings")
public class ApplicationSettingsController {

    @Autowired
    private ApplicationSettingsService service;

    @Autowired
    private JwtUtil jwtUtil;
    
    @Autowired
    private UserRepository userRepository;

    private String extractRole(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing or invalid Authorization header");
        }
        String token = authHeader.substring(7);
        try {
            String role = jwtUtil.getRoleFromToken(token);
            return role != null ? role.trim() : null;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid token");
        }
    }
    
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
    
    private void assertSettingsAccess(User user) 
    {
    	if(!AccessControlUtil.hasPermission(user, user.getCanManageSettings()))
    	{
    		 throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
    	}
    }

    @GetMapping("/getSettings")
    public ResponseEntity<?> getSettings(@RequestHeader(value = "Authorization", required = false) String authHeader) {
    	 User user = extractUser(authHeader);
    	 assertSettingsAccess(user);
        ApplicationSettingsDTO dto = service.getSettings();
        return dto != null ? ResponseEntity.ok(dto) : ResponseEntity.noContent().build();
    }

    @PostMapping("/create")
    public ResponseEntity<?> createSettings(@RequestBody ApplicationSettingsDTO dto,
                                            @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
   	 	assertSettingsAccess(user);
        ApplicationSettingsDTO saved = service.createOrUpdateSettings(dto);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/update")
    public ResponseEntity<?> updateSettings(@RequestBody ApplicationSettingsDTO dto,
                                            @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
   	 	assertSettingsAccess(user);
        ApplicationSettingsDTO saved = service.createOrUpdateSettings(dto);
        return ResponseEntity.ok(saved);
    }
}
