package com.snowCool.serviceImpl;

import com.snowCool.dto.LoginRequestDTO;
import com.snowCool.dto.LoginResponseDTO;
import com.snowCool.config.JwtUtil;
import com.snowCool.exception.CustomException;
import com.snowCool.model.User;
import com.snowCool.repositories.UserRepository;
import com.snowCool.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import com.snowCool.service.UserService;

import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import jakarta.annotation.PostConstruct;
import org.springframework.security.crypto.password.PasswordEncoder;

@Service
public class UserServiceImpl implements UserService {
    private static final Logger logger = LoggerFactory.getLogger(UserServiceImpl.class);
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public LoginResponseDTO login(LoginRequestDTO loginRequestDTO) {
        logger.info("Login attempt for username: {}", loginRequestDTO.getUsername());
        // Validate input
        if (loginRequestDTO.getUsername() == null || loginRequestDTO.getUsername().isEmpty() ||
            loginRequestDTO.getPassword() == null || loginRequestDTO.getPassword().isEmpty()) {
            throw new CustomException("Username and password must not be empty",HttpStatus.NOT_FOUND);
        }

        // Fetch user by username using repository method
        User user = userRepository.findByUsername(loginRequestDTO.getUsername());
        logger.info("User found: {}", user != null ? user.getUsername() : "null");
        if (user == null) {
            throw new CustomException("Invalid username or password",HttpStatus.NOT_FOUND);
        }

        // Validate password using PasswordEncoder
        if (!passwordEncoder.matches(loginRequestDTO.getPassword(), user.getPassword())) {
            throw new CustomException("Invalid username or password",HttpStatus.NOT_FOUND);
        }

        // Enforce active status
        if (user.getActive() != null && !user.getActive()) {
            throw new CustomException("Account disabled. Contact administrator.",HttpStatus.NOT_FOUND);
        }

        // Fetch role internally
        String role = user.getRole(); // "ADMIN" or "Employee"

        // Generate JWT token
        String token = jwtUtil.generateToken(user.getUsername(), role);
        LoginResponseDTO response = new LoginResponseDTO();
        response.setId(user.getId());
        response.setToken(token);
        response.setRole(role);
        response.setCanCreateCustomers(user.getCanCreateCustomer());
        response.setCanManageChallans(user.getCanManageChallans());
        response.setCanManageGoodsItems(user.getCanManageGoodsItems());
        response.setCanManageProfiles(user.getCanManageProfiles());
        response.setCanManageSettings(user.getCanManageSettings());
        response.setCanManagePassbook(user.getCanManagePassbook());
        return response;
    }

    @Override
    public User login(String username, String password) {
        if (username == null || username.isEmpty() || password == null || password.isEmpty()) {
            throw new CustomException("Username and password must not be empty",HttpStatus.NOT_FOUND);
        }
        User user = userRepository.findByUsername(username);
        if (user == null || !passwordEncoder.matches(password, user.getPassword())) {
            throw new CustomException("Invalid username or password",HttpStatus.NOT_FOUND);
        }
        return user;
    }

    @Override
    public User saveUser(User user) {
        User existing = userRepository.findByUsername(user.getUsername());

        // Allow same user to update, but block duplicates
        if (existing != null && (user.getId() == null || !existing.getId().equals(user.getId()))) {
            throw new CustomException("User already exists",HttpStatus.NOT_FOUND);
        }

        // If creating or updating password field is provided, encode it before saving
        if (user.getPassword() != null && !user.getPassword().isBlank()) {
            // if password already looks like BCrypt (starts with $2a/$2b/$2y), avoid double-encoding
            String raw = user.getPassword();
            if (!raw.startsWith("$2a$") && !raw.startsWith("$2b$") && !raw.startsWith("$2y$")) {
                user.setPassword(passwordEncoder.encode(raw));
            }
        }

        return userRepository.save(user);
    }


    @PostConstruct
    public void printAllUsers() {
        logger.info("Printing all users in the database:");
        for (User u : userRepository.findAll()) {
            // Do not log raw passwords — only username and role for auditing
            logger.info("Username: {}, Role: {}", u.getUsername(), u.getRole());
        }
    }
    
    @Override
    public User findById(Long id) {

        Optional<User> optional = userRepository.findById(id);

        if(!optional.isEmpty())
        {
            return optional.get();
        }
        else
        {
            return null;
        }

    }
    
    @Override
    public boolean deleteById(Long id) {
        if (userRepository.existsById(id)) {
            userRepository.deleteById(id);
            return true;
        }
        return false;
    }
}
