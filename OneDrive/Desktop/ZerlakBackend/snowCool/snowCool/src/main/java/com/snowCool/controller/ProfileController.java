package com.snowCool.controller;

import com.snowCool.dto.ProfileDTO;
import com.snowCool.exception.CustomException;
import com.snowCool.service.ProfileService;
import com.snowCool.util.AccessControlUtil;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.snowCool.config.JwtUtil;
import com.snowCool.repositories.UserRepository;
import com.snowCool.model.User;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.ByteArrayResource;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.Map;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.Part;
import java.util.Collection;
import java.util.stream.Collectors;
import java.util.HashMap;

@RestController
@RequestMapping("/api/v1/profiles")
public class ProfileController {
    @Autowired
    private ProfileService profileService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private JwtUtil jwtUtil;

    @Value("${profile.logo.upload-dir:uploads}")
    private String uploadDir;

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

    private void assertAccess(User user) 
    {
    	if(!AccessControlUtil.hasPermission(user, user.getCanManageProfiles()))
    	{
    		 throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
    	}
    }
    
    @PostMapping("/save")
    public ProfileDTO createProfile(@RequestBody ProfileDTO profileDTO,
                                    @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertAccess(user);
        return profileService.createProfile(profileDTO);
    }

    @GetMapping("/getById/{id}")
    public ProfileDTO getProfileById(@PathVariable int id,
                                     @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertAccess(user);
        return profileService.getProfileById(1);
    }

    @GetMapping("/getAllProfiles")
    public List<ProfileDTO> getAllProfiles(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertAccess(user);
        return profileService.getAllProfiles();
    }

    @PutMapping("/updateById/{id}")
    public ProfileDTO updateProfile(@PathVariable int id, @RequestBody ProfileDTO profileDTO,
                                    @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertAccess(user);
        return profileService.updateProfile(1, profileDTO);
    }

    @DeleteMapping("/deleteById/{id}")
    public void deleteProfile(@PathVariable int id,
                              @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertAccess(user);
        profileService.deleteProfile(id);
    }

    @PutMapping("/{id}/terms")
    public void updateTermsAndConditions(@PathVariable int id,
                                         @RequestBody String termsAndConditions,
                                         @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertAccess(user);
        profileService.updateTermsAndConditions(id, termsAndConditions);
    }

    // New: upload a logo for a profile (robust handling) - PNG only
    @PostMapping(path = "/{id}/logo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadLogo(@PathVariable int id,
                                        @RequestParam(value = "file", required = false) MultipartFile file,
                                        HttpServletRequest request,
                                        @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertAccess(user);
        try {
            byte[] fileBytes = null;
            String filename = null;
            if (file == null || file.isEmpty()) {
                try {
                    Collection<Part> parts = request.getParts();
                    Part candidate = null;
                    for (Part p : parts) {
                        if (p.getSize() > 0) {
                            candidate = p;
                            break;
                        }
                    }
                    if (candidate != null) {
                        String partContentType = candidate.getContentType();
                        if (partContentType == null || !partContentType.equalsIgnoreCase("image/png")) {
                            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Only PNG images are allowed");
                        }
                        filename = "profile-" + id + "-" + UUID.randomUUID() + ".png";
                        Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
                        Files.createDirectories(uploadPath);
                        Path target = uploadPath.resolve(filename);
                        try (var is = candidate.getInputStream()) {
                            fileBytes = is.readAllBytes();
                            Files.write(target, fileBytes);
                        }
                        profileService.updateLogoWithBytes(id, filename, "image/png", fileBytes);
                        String url = "/api/profiles/" + id + "/logo";
                        return ResponseEntity.ok(Map.of("fileName", filename, "url", url));
                    }
                } catch (ResponseStatusException e) {
                    throw e;
                } catch (Exception e) {
                    // fall through to original error handling below
                }
            }
            if (file == null || file.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No file provided");
            }
            String contentType = file.getContentType();
            if (contentType == null || !contentType.equalsIgnoreCase("image/png")) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Only PNG images are allowed");
            }
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            Files.createDirectories(uploadPath);
            filename = "profile-" + id + "-" + UUID.randomUUID() + ".png";
            Path target = uploadPath.resolve(filename);
            fileBytes = file.getBytes();
            Files.write(target, fileBytes);
            profileService.updateLogoWithBytes(id, filename, "image/png", fileBytes);
            String url = "/api/profiles/" + id + "/logo";
            return ResponseEntity.ok(Map.of("fileName", filename, "url", url));
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to store file: " + e.getMessage());
        }
    }

    // Helper: prefer static/logo.png, fall back to static/logo.svg if png not available
    private Resource getDefaultLogoResource() {
        ClassPathResource png = new ClassPathResource("static/logo.png");
        if (png.exists()) return png;
        ClassPathResource svg = new ClassPathResource("static/logo.svg");
        if (svg.exists()) return svg;
        return null;
    }

    // New: serve the logo for a profile. If not uploaded or missing, serve default static logo (PNG preferred, SVG fallback)
    @GetMapping(path = "/{id}/logo")
    public ResponseEntity<Resource> getLogo(@PathVariable int id) {
        try {
            // Try DB blob first
            byte[] logoBytes = null;
            String contentType = null;
            String fileName = null;
            try {
                logoBytes = profileService.getLogoBytes(id);
                contentType = profileService.getLogoContentType(id);
                fileName = profileService.getLogoFileName(id);
            } catch (com.snowCool.exception.CustomException e) {
                // profile not found - return 404
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
            }

            if (logoBytes != null && logoBytes.length > 0) {
                MediaType media = MediaType.APPLICATION_OCTET_STREAM;
                if (contentType != null && !contentType.isBlank()) {
                    try { media = MediaType.parseMediaType(contentType); } catch (Exception ex) { /* ignore and use octet-stream */ }
                }
                ByteArrayResource bar = new ByteArrayResource(logoBytes);
                return ResponseEntity.ok()
                        .contentType(media)
                        .body(bar);
            }

            // If blob not present, try file on disk using stored filename
            if (fileName != null && !fileName.isBlank()) {
                Path filePath = Paths.get(uploadDir).toAbsolutePath().resolve(fileName).normalize();
                if (Files.exists(filePath)) {
                    Resource resource = new UrlResource(filePath.toUri());
                    String probeContentType = Files.probeContentType(filePath);
                    if (probeContentType == null) probeContentType = "application/octet-stream";
                    return ResponseEntity.ok()
                            .contentType(MediaType.parseMediaType(probeContentType))
                            .body(resource);
                }
            }

            // Fallback to default static logo (png preferred, svg fallback)
            Resource defaultLogo = getDefaultLogoResource();
            if (defaultLogo == null) {
                return ResponseEntity.notFound().build();
            }
            String mediaType = defaultLogo.getFilename() != null && defaultLogo.getFilename().toLowerCase().endsWith(".svg")
                    ? "image/svg+xml" : "image/png";
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(mediaType))
                    .body(defaultLogo);

        } catch (MalformedURLException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Invalid file path");
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Could not read file");
        }
    }

    // Diagnostic endpoint to inspect incoming multipart requests
    @PostMapping(path = "/{id}/logo/debug", consumes = MediaType.ALL_VALUE)
    public ResponseEntity<?> debugUpload(@PathVariable int id,
                                         HttpServletRequest request,
                                         @RequestHeader(value = "Authorization", required = false) String authHeader) {
        // re-run auth check (optional) to keep endpoint protected
        User user = null;
        try {
        	assertAccess(user);
        } catch (ResponseStatusException e) {
            // bubble up auth failures
            throw e;
        } catch (Exception ex) {
            // if token invalid, return minimal info to help debugging
        }

        Map<String, Object> info = new HashMap<>();
        info.put("contentType", request.getContentType());

        // headers
        Map<String, String> headers = request.getHeaderNames() == null ? Map.of() :
            java.util.Collections.list(request.getHeaderNames()).stream()
                .collect(Collectors.toMap(h -> h, request::getHeader));
        info.put("headers", headers);

        // try to list parts
        try {
            Collection<Part> parts = request.getParts();
            List<String> partNames = parts.stream().map(Part::getName).collect(Collectors.toList());
            info.put("parts", partNames);
            // also provide sizes
            Map<String, Long> partSizes = parts.stream().collect(Collectors.toMap(Part::getName, Part::getSize));
            info.put("partSizes", partSizes);
        } catch (Exception e) {
            info.put("partsError", e.getMessage());
        }

        return ResponseEntity.ok(info);
    }

    // New fallback: accept base64 JSON upload for clients that can't send multipart - PNG only
    @PostMapping(path = "/{id}/logo/base64", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<?> uploadLogoBase64(@PathVariable int id,
                                             @RequestBody Map<String, String> body,
                                             @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertAccess(user);
        String data = body.get("data");
        String providedName = body.get("fileName");
        if (data == null || data.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Missing 'data' (base64) field");
        }
        try {
            boolean looksLikePng = false;
            if (data.startsWith("data:")) {
                int semicolon = data.indexOf(';');
                int comma = data.indexOf(',');
                String mime = null;
                if (semicolon > 0 && semicolon < comma) {
                    mime = data.substring(5, semicolon);
                } else if (comma > 0) {
                    mime = data.substring(5, comma);
                }
                if (mime != null && mime.equalsIgnoreCase("image/png")) looksLikePng = true;
                if (comma > 0) data = data.substring(comma + 1);
            }
            if (!looksLikePng && providedName != null && providedName.toLowerCase().endsWith(".png")) {
                looksLikePng = true;
            }
            if (!looksLikePng) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Only PNG images are allowed (base64 data must be PNG)");
            }
            byte[] bytes = java.util.Base64.getDecoder().decode(data);
            String filename = "profile-" + id + "-" + UUID.randomUUID() + ".png";
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            Files.createDirectories(uploadPath);
            Path target = uploadPath.resolve(filename);
            Files.write(target, bytes);
            profileService.updateLogoWithBytes(id, filename, "image/png", bytes);
            String url = "/api/profiles/" + id + "/logo";
            return ResponseEntity.ok(Map.of("fileName", filename, "url", url));
        } catch (IllegalArgumentException iae) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid base64 data");
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to store file: " + e.getMessage());
        }
    }
}
