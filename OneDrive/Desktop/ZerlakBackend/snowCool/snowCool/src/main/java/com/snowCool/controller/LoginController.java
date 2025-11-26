package com.snowCool.controller;

import com.snowCool.dto.LoginRequestDTO;
import com.snowCool.dto.LoginResponseDTO;
import com.snowCool.model.User;
import com.snowCool.model.JwtBlacklist;
import com.snowCool.service.UserService;
import com.snowCool.repositories.UserRepository;
import com.snowCool.repositories.JwtBlacklistRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import com.snowCool.config.JwtUtil;

import java.time.LocalDateTime;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api/v1/auth")
public class LoginController {
    private static final Logger logger = LoggerFactory.getLogger(LoginController.class);

    @Autowired
    private UserService userService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private JwtBlacklistRepository jwtBlacklistRepository;

    public LoginController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequestDTO loginRequest) {
        try {
            LoginResponseDTO response = userService.login(loginRequest);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestParam(value = "token", required = false) String tokenParam,
            @RequestBody(required = false) java.util.Map<String, Object> body) {
        // Determine token from header, query param, or body
        String token = null;
        String source = "none";
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
            source = "header";
        }
        if ((token == null || token.isBlank()) && tokenParam != null && !tokenParam.isBlank()) {
            token = tokenParam;
            source = "query";
        }
        if ((token == null || token.isBlank()) && body != null) {
            Object t = body.get("token");
            if (t != null) {
                token = String.valueOf(t);
                source = "body";
            }
        }

        if (token == null || token.isBlank()) {
            logger.warn("Logout called without token (no Authorization header, query param, or body)");
            return ResponseEntity.badRequest().body("Missing token: provide Authorization header, ?token=... or JSON body {\"token\":\"...\"}");
        }

        // Mask token for logs (do not log full token)
        String masked = token.length() <= 10 ? "****" : (token.substring(0, 6) + "..." + token.substring(token.length() - 4));
        logger.info("Logout requested - token source={}, token={}", source, masked);

        try {
            // If token invalid, still blacklist to prevent reuse
            JwtBlacklist jb = new JwtBlacklist(token, java.time.LocalDateTime.now());
            if (!jwtBlacklistRepository.existsByToken(token)) {
                jwtBlacklistRepository.save(jb);
                logger.info("Token blacklisted: {}", masked);
            } else {
                logger.info("Token already blacklisted: {}", masked);
            }
            return ResponseEntity.ok("Logged out");
        } catch (Exception e) {
            logger.error("Error while blacklisting token: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
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

    private boolean isAdmin(User user) {
        String role = user.getRole();
        return role != null && "ADMIN".equalsIgnoreCase(role.trim());
    }

    @GetMapping("/me")
    public ResponseEntity<?> me(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        // sanitize response: do not include password
        return ResponseEntity.ok(new java.util.LinkedHashMap<String, Object>() {{
            put("username", user.getUsername());
            put("role", user.getRole());
            put("active", user.getActive());
            put("canCreateCustomer", user.getCanCreateCustomer());
            put("canManageGoodsItems", user.getCanManageGoodsItems());
            put("canManageChallans", user.getCanManageChallans());
            put("canManageProfiles", user.getCanManageProfiles());
            put("canManageSettings", user.getCanManageSettings());
        }});
    }

    @PostMapping("/create")
    public ResponseEntity<?> createUser(@RequestBody User user,
                                        @RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            User caller = extractUser(authHeader);
            if (!isAdmin(caller)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied: only ADMIN can create users");
            }
            User savedUser = userService.saveUser(user);
            return ResponseEntity.ok(savedUser);
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
