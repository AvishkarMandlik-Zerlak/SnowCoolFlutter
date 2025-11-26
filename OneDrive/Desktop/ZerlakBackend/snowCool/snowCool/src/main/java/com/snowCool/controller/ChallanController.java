package com.snowCool.controller;

import com.snowCool.config.JwtUtil;
import com.snowCool.dto.ChallanDTO;
import com.snowCool.dto.CustomerDTO;
import com.snowCool.exception.CustomException;
import com.snowCool.model.User;
import com.snowCool.pdfgenerator.RecievedChallanPdf;
import com.snowCool.repositories.UserRepository;
import com.snowCool.service.ChallanService;
import com.snowCool.util.AccessControlUtil;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/v1/challans")
public class ChallanController {

    @Autowired private ChallanService challanService;
    @Autowired private JwtUtil jwtUtil;
    @Autowired private UserRepository userRepository;
    @Autowired private RecievedChallanPdf pdfService; // Fixed typo: pdfServcie → pdfService

    // === AUTH HELPERS ===
    private String extractRole(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new CustomException("Missing or invalid Authorization header",HttpStatus.UNAUTHORIZED);
        }
        String token = authHeader.substring(7);
        try {
            String role = jwtUtil.getRoleFromToken(token);
            return role != null ? role.trim() : null;
        } catch (Exception ex) {
            throw new CustomException("Invalid token",HttpStatus.UNAUTHORIZED);
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
            if (user == null) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid token user");
            }
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

    private void assertChallanAccess(User user) {
        if (!AccessControlUtil.hasPermission(user, user.getCanManageChallans())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied: challan management not permitted");
        }
    }

    // === CRUD ENDPOINTS ===
    @PostMapping("/create")
    public ChallanDTO createChallan(@Valid @RequestBody ChallanDTO challanDTO,
                                    @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertChallanAccess(user);
        System.out.println("Creating challan by user: {} "+ user.getUsername());
        return challanService.createChallan(challanDTO);
    }

    @GetMapping("/getByChallanId/{id}")
    public ChallanDTO getChallanById(@PathVariable int id,
                                     @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertChallanAccess(user);
        return challanService.getChallanById(id);
    }

    @GetMapping("/getAllChallan")
    public List<ChallanDTO> getAllChallans(@RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertChallanAccess(user);
        return challanService.getAllChallans();
    }

    @PutMapping("/updateChallanById/{id}")
    public ResponseEntity<String> updateChallan(@PathVariable int id,
                                                @Valid @RequestBody ChallanDTO challanDTO,
                                                @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertChallanAccess(user);
        System.out.println("Updating challan {} by user: {} "+ id + user.getUsername());
        return challanService.updateChallan(id, challanDTO);
    }

    @DeleteMapping("/deleteChallanById/{id}")
    public ResponseEntity<Void> deleteChallan(@PathVariable int id,
                                              @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertChallanAccess(user);
        challanService.deleteChallan(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/deleteMultipleChallans")
    public ResponseEntity<String> deleteMultipleChallans(@RequestBody List<Integer> ids,
                                                         @RequestHeader(value = "Authorization", required = false) String authHeader) {
        User user = extractUser(authHeader);
        assertChallanAccess(user);
        return challanService.deleteMultipleChallans(ids);
    }

    // === PDF DOWNLOAD ===
    @GetMapping(value = "/download/{challanId}", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<ByteArrayResource> download(@PathVariable int challanId,
                                                      @RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            User user = extractUser(authHeader);
            assertChallanAccess(user);

            byte[] pdfBytes = pdfService.generatePdfBytes(challanId);
            String fileName = "Challan_" + challanId + ".pdf";

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDisposition(ContentDisposition.attachment().filename(fileName).build());

            System.out.println("PDF generated for challan {} by user: {}"+ challanId + user.getUsername());

            return ResponseEntity.ok()
                    .headers(headers)
                    .body(new ByteArrayResource(pdfBytes));

        } catch (Exception e) {
        	System.out.println("PDF generation failed for challan {}" + challanId +e);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
    
    
    @GetMapping("/getCustomersChallanNumbers/{id}")
    public List<String> getChallanByCustomerId(@PathVariable int id, @RequestHeader(value = "Authorization", required = false) String authHeader)
    {
    	User user = extractUser(authHeader);  	
    	assertChallanAccess(user);
    	return challanService.getChallanByCustomerId(id);
    }
    
    @GetMapping("/getCustomersChallan/{challanNumber}")
    public ChallanDTO getChallanByChallanNumber(@PathVariable String challanNumber,@RequestHeader(value = "Authorization", required = false) String authHeader)
    {
    	String safeChallanNumber = challanNumber.replace("_", "/");
    	User user = extractUser(authHeader);
    	assertChallanAccess(user);
    	return challanService.getChallanByChallanNumber(safeChallanNumber);
    }
    
    @GetMapping("/searchChallans")
    public List<ChallanDTO> searchChallans(@RequestParam(required = false) String name,
           							 @RequestParam(required = false) String contactNumber,
           							 @RequestParam(required = false) String email,
           							 @RequestHeader(value = "Authorization", required = false) String authHeader)

    {
    	User user = extractUser(authHeader); 
        assertChallanAccess(user);
        return challanService.searchChallans(name, contactNumber, email);
    }

//    @PostMapping("/download/bulk")
//    public ResponseEntity<byte[]> downloadBulk(@RequestBody int[] ids) throws Exception {
//        byte[] pdf = pdfService.generateMultipleChallansPdf(ids);
//        return ResponseEntity.ok()
//                .contentType(MediaType.APPLICATION_PDF)
//                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=Multiple_Challans_" + LocalDate.now() + ".pdf")
//                .body(pdf);
//    }
    
    @GetMapping("/page")
    public Page<ChallanDTO> getChallansPage(@RequestParam(defaultValue = "0") int page,
                                             @RequestParam(defaultValue = "10") int size,
                                             @RequestHeader(value = "Authorization", required = false) String authHeader) {
    	User user = extractUser(authHeader);
        assertChallanAccess(user);
        return challanService.getChallansPage(PageRequest.of(page, size));
    }
}
    
