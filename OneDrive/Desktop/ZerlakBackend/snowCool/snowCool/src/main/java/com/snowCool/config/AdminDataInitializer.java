package com.snowCool.config;

import com.snowCool.model.User;
import com.snowCool.repositories.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class AdminDataInitializer implements ApplicationRunner {
    private static final Logger logger = LoggerFactory.getLogger(AdminDataInitializer.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.admin.username:admin}")
    private String adminUsername;

    @Value("${app.admin.password:admin}")
    private String adminPassword;

    @Value("${app.admin.role:ADMIN}")
    private String adminRole;

    public AdminDataInitializer(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        try {
            User existing = userRepository.findByUsername(adminUsername);
            if (existing == null) {
                logger.info("No admin user found. Creating default admin user: {}", adminUsername);
                User admin = new User();
                admin.setUsername(adminUsername);
                admin.setPassword(passwordEncoder.encode(adminPassword));
                admin.setRole(adminRole);
                admin.setActive(true);
                userRepository.save(admin);
                logger.info("Admin user created successfully");
            } else {
                boolean needsUpdate = false;
                // Ensure role present
                if (existing.getRole() == null || existing.getRole().isBlank()) {
                    existing.setRole(adminRole);
                    needsUpdate = true;
                }
                // Ensure active is true by default if null
                if (existing.getActive() == null) {
                    existing.setActive(true);
                    needsUpdate = true;
                }
                // If stored hash doesn't match the configured plain password, reset it
                String stored = existing.getPassword();
                if (stored == null || !passwordEncoder.matches(adminPassword, stored)) {
                    logger.warn("Admin password does not match configured value. Resetting admin password.");
                    existing.setPassword(passwordEncoder.encode(adminPassword));
                    needsUpdate = true;
                }
                if (needsUpdate) {
                    userRepository.save(existing);
                    logger.info("Admin user updated (role/active/password)");
                } else {
                    logger.info("Admin user '{}' already exists and is up-to-date.", adminUsername);
                }
            }
        } catch (Exception e) {
            logger.error("Failed to initialize/update admin user", e);
            throw e;
        }
    }
}
