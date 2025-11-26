package com.snowCool.controller;

import com.snowCool.model.User;
import com.snowCool.repositories.UserRepository;
import com.snowCool.service.UserService;

import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import com.snowCool.config.JwtUtil;
import com.snowCool.exception.CustomException;

import java.util.List;

@RestController
@RequestMapping("/api/v1/settings/users")
public class UserSettingsController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtil jwtUtil;

    private void requireAdmin(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing or invalid Authorization header");
        }
        String token = authHeader.substring(7);
        String username;
        try {
            username = jwtUtil.getUsernameFromToken(token);
            System.out.println(username);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid token");
        }
        User caller = userRepository.findByUsername(username);
        if (caller == null || (caller.getActive() != null && !caller.getActive())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Account disabled");
        }
        if (!"ADMIN".equalsIgnoreCase(caller.getRole())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied: only ADMIN");
        }
    }

    @GetMapping("/getAllUsers")
    public List<User> listUsers(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        requireAdmin(authHeader);
        return userRepository.findAll();
    }

    @PostMapping("/create")
    public ResponseEntity<?> createOrUpdateUser(
            @RequestBody User user,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        
        requireAdmin(authHeader);

        User existingUser = (user.getId() != null) ? userService.findById(user.getId()) : null;

        if (existingUser != null) {
            // Copy all new fields except ID
            BeanUtils.copyProperties(user, existingUser, "id");
            user = existingUser;
        }

        User saved = userService.saveUser(user);
        return ResponseEntity.ok(saved);
    }


    @PutMapping("/{username}/status")
    public ResponseEntity<?> updateStatus(@PathVariable String username,
                                          @RequestParam boolean active,
                                          @RequestHeader(value = "Authorization", required = false) String authHeader) {
        requireAdmin(authHeader);
        User user = userRepository.findByUsername(username);
        if (user == null) throw new CustomException("User not found",HttpStatus.NOT_FOUND);
        user.setActive(active);
        return ResponseEntity.ok(userRepository.save(user).getActive());
    }

    @PutMapping("/{username}/permissions")
    public ResponseEntity<?> updatePermissions(@PathVariable String username,
                                               @RequestBody User permissions,
                                               @RequestHeader(value = "Authorization", required = false) String authHeader) {
        requireAdmin(authHeader);
        User user = userRepository.findByUsername(username);
        if (user == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found");
        if (permissions.getCanCreateCustomer() != null) user.setCanCreateCustomer(permissions.getCanCreateCustomer());
        if (permissions.getCanManageGoodsItems() != null) user.setCanManageGoodsItems(permissions.getCanManageGoodsItems());
        if (permissions.getCanManageChallans() != null) user.setCanManageChallans(permissions.getCanManageChallans());
        if (permissions.getCanManageProfiles() != null) user.setCanManageProfiles(permissions.getCanManageProfiles());
        if (permissions.getCanManageSettings() != null) user.setCanManageSettings(permissions.getCanManageSettings());
        return ResponseEntity.ok(userRepository.save(user));
    }
    
        
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<String> deleteUser(@PathVariable Long id, @RequestHeader(value = "Authorization", required = false) String authHeader) {
        
        requireAdmin(authHeader);
        boolean deleted = userService.deleteById(id);
        if (deleted) {
            return ResponseEntity.ok("User with id : "+id+" is deleted.");
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("User not found with id: " + id);
        }
    }
}
 