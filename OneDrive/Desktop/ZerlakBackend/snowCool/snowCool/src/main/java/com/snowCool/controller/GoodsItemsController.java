package com.snowCool.controller;

import com.snowCool.model.GoodsItems;
import com.snowCool.service.GoodsItemsService;
import com.snowCool.util.AccessControlUtil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import com.snowCool.config.JwtUtil;
import com.snowCool.repositories.UserRepository;
import com.snowCool.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.dao.DataIntegrityViolationException;
import com.snowCool.repositories.GoodsItemsRepository;

@RestController
@RequestMapping("/api/v1/goods")
@SecurityRequirement(name = "bearerAuth")
public class GoodsItemsController {
    private static final Logger logger = LoggerFactory.getLogger(GoodsItemsController.class);
    @Autowired
    private GoodsItemsService goodsItemsService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private GoodsItemsRepository goodsItemsRepository;

    private User extractUser(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Missing or invalid Authorization header");
        }
        String token = authHeader.substring(7);
        try {
            String username = jwtUtil.getUsernameFromToken(token);
            logger.info("[GoodsItems] Authenticated username: {}", username);
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
        boolean admin = role != null && "ADMIN".equalsIgnoreCase(role.trim());
        logger.info("[GoodsItems] DB role: {}, isAdmin(DB): {}", role, admin);
        return admin;
    }
    
    private void assertChallanAccess(User user) {
        if (!AccessControlUtil.hasPermission(user, user.getCanManageChallans())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied: challan management not permitted");
        }
    }

    private String extractRoleClaim(String authHeader) {
        String token = authHeader.substring(7);
        try {
            String role = jwtUtil.getRoleFromToken(token);
            String trimmed = role != null ? role.trim() : null;
            logger.info("[GoodsItems] JWT role claim: {}", trimmed);
            return trimmed;
        } catch (Exception e) {
            logger.warn("[GoodsItems] Failed to extract role claim from token");
            return null;
        }
    }
    @PostMapping("/save")
    public ResponseEntity<GoodsItems> createGoodsItem(@RequestBody GoodsItems item,
                                                      @RequestHeader(value = "Authorization", required = false) String authHeader) {

        System.out.println("Creating Goods Item: " + item);
        User user = extractUser(authHeader);
        String roleClaim = extractRoleClaim(authHeader);
        boolean allowed = isAdmin(user) || (roleClaim != null && roleClaim.equalsIgnoreCase("ADMIN")) || Boolean.TRUE.equals(user.getCanManageGoodsItems());
        logger.info("[GoodsItems] Access check -> user: {}, dbRole: {}, jwtRole: {}, canManageGoods: {}, allowed: {}",
                user.getUsername(), user.getRole(), roleClaim, user.getCanManageGoodsItems(), allowed);
        assertChallanAccess(user);

        // Efficient repository-level duplicate check (case-insensitive)
        if (item.getName() == null || item.getName().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "name is required");
        }
        String name = item.getName().trim();
        if (goodsItemsRepository.existsByNameIgnoreCase(name)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Goods item with same name already exists");
        }

        try {
            item.setName(name);
            GoodsItems saved = goodsItemsService.createGoodsItem(item);
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (DataIntegrityViolationException dive) {
            logger.warn("Unique constraint violated when creating goods item: {}", name);
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Goods item with same name already exists");
        } catch (Exception ex) {
            logger.error("Error creating goods item", ex);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to create goods item");
        }
    }

    @GetMapping("getById/{id}")
    public ResponseEntity<GoodsItems> getGoodsItem(@PathVariable int id,
                                                   @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	 User user = extractUser(authHeader);
         assertChallanAccess(user);
        GoodsItems item = goodsItemsService.getGoodsItem(id);
        return item != null ? ResponseEntity.ok(item) : ResponseEntity.notFound().build();
    }

    @GetMapping("/getAllGoods")
    public ResponseEntity<List<GoodsItems>> getAllGoodsItems(@RequestHeader(value = "Authorization", required = false) String authHeader) {
    	 User user = extractUser(authHeader);
         assertChallanAccess(user);
        return ResponseEntity.ok(goodsItemsService.getAllGoodsItems());
    }

    @PutMapping("updateById/{id}")
    public ResponseEntity<GoodsItems> updateGoodsItem(@PathVariable int id, @RequestBody GoodsItems item,
                                                      @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	 User user = extractUser(authHeader);
         assertChallanAccess(user);

        if (item.getName() == null || item.getName().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "name is required");
        }
        String name = item.getName().trim();
        // Check duplicate name excluding the current item
        java.util.Optional<GoodsItems> existing = goodsItemsRepository.findByNameIgnoreCase(name);
        if (existing.isPresent() && !existing.get().getId().equals(id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Another goods item with same name already exists");
        }

        try {
            item.setName(name);
            GoodsItems updated = goodsItemsService.updateGoodsItem(id, item);
            return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
        } catch (DataIntegrityViolationException dive) {
            logger.warn("Unique constraint violated when updating goods item: {}", name);
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Goods item with same name already exists");
        } catch (Exception ex) {
            logger.error("Error updating goods item", ex);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to update goods item");
        }
    }

    @DeleteMapping("deleteById/{id}")
    public ResponseEntity<Void> deleteGoodsItem(@PathVariable int id,
                                                @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	 User user = extractUser(authHeader);
         assertChallanAccess(user);
        goodsItemsService.deleteGoodsItem(id);
        return ResponseEntity.noContent().build();
    }
}
