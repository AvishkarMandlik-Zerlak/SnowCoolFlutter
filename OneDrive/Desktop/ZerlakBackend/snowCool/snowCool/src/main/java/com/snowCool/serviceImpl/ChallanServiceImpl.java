// src/main/java/com/snowCool/serviceImpl/ChallanServiceImpl.java
package com.snowCool.serviceImpl;

import com.snowCool.dto.ChallanDTO;
import com.snowCool.dto.ChallanItemDTO;
import com.snowCool.dto.CustomerDTO;
import com.snowCool.model.*;
import com.snowCool.repositories.*;
import com.snowCool.service.ChallanService;

import tools.jackson.databind.ext.javatime.deser.LocalDateDeserializer;

import com.snowCool.exception.CustomException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@Transactional
public class ChallanServiceImpl implements ChallanService {

    @Autowired private ChallanRepository challanRepository;
    @Autowired private CustomerRepository customerRepository;
    @Autowired private ApplicationSettingsRepository appSettingsRepository;
    @Autowired private CustomerInventoryRepository customerInventoryRepository;

    public Challan dtoToEntity(ChallanDTO dto) {
        Challan challan = new Challan();
        
        System.out.println(dto);
        
        Customer customer = customerRepository.findById(dto.getCustomerId())
            .orElseThrow(() -> new CustomException("Customer not found: " + dto.getCustomerId(),HttpStatus.NOT_FOUND));

        challan.setCustomer(customer);
        challan.setSiteLocation(dto.getSiteLocation());
        challan.setVehicleNumber(dto.getVehicleNumber());
        challan.setDriverName(dto.getDriverName());
        challan.setDriverNumber(dto.getDriverNumber());  // FIXED
        challan.setTransporter(dto.getTransporter());
        challan.setDate(dto.getDate());                  // FIXED
        challan.setDeliveryDetails(dto.getDeliveryDetails());
        challan.setPurchaseOrderNo(dto.getPurchaseOrderNo());
        challan.setDeposite(dto.getDeposite());
        challan.setReturnedAmount(dto.getReturnedAmount());
        challan.setDepositeNarration(dto.getDepositeNarration());
        challan.setDeliveredChallanNo(dto.getDeliveredChallanNo());

        if (dto.getChallanType() != null) {
        	challan.setChallanType(dto.getChallanType());
        } else {
        	challan.setChallanType(ChallanType.RECEIVED);
        }
        
        
        return challan;
    }

    public ChallanDTO entityToDto(Challan challan) {
        ChallanDTO dto = new ChallanDTO();
        dto.setId(challan.getId());
        dto.setCustomerId(challan.getCustomer().getId());
        dto.setCustomerName(challan.getCustomer().getName());
        dto.setVehicleNumber(challan.getVehicleNumber());
        dto.setDriverName(challan.getDriverName());
        dto.setTransporter(challan.getTransporter());
        dto.setChallanNumber(challan.getChallanNumber());
        dto.setDriverNumber(challan.getDriverNumber());  // FIXED
        dto.setDate(challan.getDate());                  // FIXED
        dto.setSiteLocation(challan.getSiteLocation());
        dto.setDeposite(challan.getDeposite());
        dto.setReturnedAmount(challan.getReturnedAmount());
        dto.setDeliveryDetails(challan.getDeliveryDetails());
        dto.setPurchaseOrderNo(challan.getPurchaseOrderNo());
        dto.setDepositeNarration(challan.getDepositeNarration());
        dto.setDeliveredChallanNo(challan.getDeliveredChallanNo());
        dto.setItems(entityItemsToDtos(challan.getItems()));

        if (challan.getChallanType() != null) {
            dto.setChallanType(challan.getChallanType());
        } else {
            dto.setChallanType(ChallanType.RECEIVED);
        }
        return dto;
    }
    public List<ChallanItem> dtoItemsToEntities(List<ChallanItemDTO> dtos, Challan challan) {
        if (dtos == null) return null;
        return dtos.stream().map(dto -> {
            ChallanItem item = new ChallanItem();
            item.setChallan(challan);
//            item.setId(dto.getId());
            item.setName(dto.getName());
            item.setDeliveredQty(dto.getDeliveredQty());
            item.setReceivedQty(dto.getReceivedQty());
            item.setSrNo(dto.getSrNo());
            item.setGoodsItemId(dto.getGoodsItemId());
            item.setType(dto.getType());
            return item;
        }).collect(Collectors.toList());
    }

    public List<ChallanItemDTO> entityItemsToDtos(List<ChallanItem> items) {
        if (items == null) return null;
        return items.stream().map(item -> {
            ChallanItemDTO dto = new ChallanItemDTO();
            dto.setId(item.getId());
            dto.setName(item.getName());
            dto.setDeliveredQty(item.getDeliveredQty());
            dto.setReceivedQty(item.getReceivedQty());
            dto.setSrNo(item.getSrNo());
            dto.setGoodsItemId(item.getGoodsItemId());
            dto.setType(item.getType());
            return dto;
        }).collect(Collectors.toList());
    }

    private String formatChallanNumber(ApplicationSettings s, ChallanType type) {
        LocalDate now = LocalDate.now();
        String policy = s.getChallanSequenceResetPolicy();
        LocalDate last = s.getSequenceLastResetDate();
        boolean reset = false;
        if (policy != null) {
            switch (policy.toUpperCase()) {
                case "YEAR": reset = last == null || last.getYear() != now.getYear(); break;
                case "MONTH": reset = last == null || last.getYear() != now.getYear() || last.getMonthValue() != now.getMonthValue(); break;
                case "DAY": reset = last == null || !last.equals(now); break;
            }
        }
        if (reset) {
            s.setChallanSequence(1);
            s.setSequenceLastResetDate(now);
        }
        int next = s.getChallanSequence() == null || s.getChallanSequence() < 1 ? 1 : s.getChallanSequence();
        String year = String.valueOf(now.getYear());
        String yy = year.substring(2);
        String mm = String.format("%02d", now.getMonthValue());
        String dd = String.format("%02d", now.getDayOfMonth());

        String prefix = type == ChallanType.DELIVERED ? "DLV-" : "RCV-";
        if (s.getInvoicePrefix() != null && !s.getInvoicePrefix().isEmpty()) {
            prefix = s.getInvoicePrefix();
        }

        String format = s.getChallanNumberFormat();
        if (format == null || format.isEmpty()) {
            format = prefix + "{YYYY}-{SEQ:5}";
        }

        String result = format
            .replace("{YYYY}", year)
            .replace("{YY}", yy)
            .replace("{MM}", mm)
            .replace("{DD}", dd);
        
        Pattern p = Pattern.compile("\\{SEQ:(\\d+)\\}");
        Matcher m = p.matcher(result);
        StringBuffer sb = new StringBuffer();
        while (m.find()) {
            int width = Integer.parseInt(m.group(1));
            String padded = String.format("%0" + width + "d", next);
            m.appendReplacement(sb, Matcher.quoteReplacement(padded));
        }
        m.appendTail(sb);
        result = sb.toString();
        if (result.contains("{SEQ}")) {
            result = result.replace("{SEQ}", String.valueOf(next));
        }

        s.setChallanSequence(next + 1);
        s.setSequenceLastResetDate(now);
        return result;
    }

    private String newChallanNumberFormat(ApplicationSettings settings , ChallanType type )
    {
    	LocalDateTime now = LocalDateTime.now();
    	int year = now.getYear();
    	
    	int startYear ;
    	int endYear;
    	
    	if(now.getMonthValue() < 4)
    	{	
    		startYear = year%100 - 1;
    		endYear = year%100;
    	}
    	else
    	{
    		startYear = year%100 ;
    		endYear = year%100 + 1;
    	}
    	
    	String newChallanNumber = settings.getInvoicePrefix()+"/"+startYear+"-"+endYear+"/"+settings.getChallanSequence();
    	
    	settings.setChallanSequence(settings.getChallanSequence()+1);
    	
    	return newChallanNumber;
    }
    
    @Transactional
    public String updateDeliveredChallanItemsReceivedQuantity(
            String deliveredChallanNo,
            List<ChallanItemDTO> receivedItemDtos) {   // ← DTOs, not entities!

        Challan deliveredChallan = challanRepository.findChallanByChallanNumber(deliveredChallanNo);
        if (deliveredChallan == null) {
            throw new CustomException("Delivered Challan not found: " + deliveredChallanNo, HttpStatus.NOT_FOUND);
        }
        if (deliveredChallan.getChallanType() != ChallanType.DELIVERED) {
            throw new CustomException("Not a DELIVERED challan", HttpStatus.BAD_REQUEST);
        }

        int totalUpdated = 0;
        for (ChallanItemDTO dto : receivedItemDtos) {
            Integer originalItemId = dto.getId();  // ← This is the original Delivered item ID from Flutter!
            int receivedQty = dto.getReceivedQty() != 0 ? dto.getReceivedQty() : 0;

            if (originalItemId == null || originalItemId <= 0 || receivedQty <= 0) {
                continue;
            }

            Optional<ChallanItem> match = deliveredChallan.getItems().stream()
                .filter(item -> item.getId() != 0 && item.getId() == originalItemId)
                .findFirst();

            if (match.isPresent()) {
                ChallanItem deliveredItem = match.get();
                int newTotal = deliveredItem.getReceivedQty() + receivedQty;

                if (newTotal > deliveredItem.getDeliveredQty()) {
                    throw new CustomException("Cannot receive more than delivered", HttpStatus.BAD_REQUEST);
                }

                deliveredItem.setReceivedQty(newTotal);
                totalUpdated++;
                System.out.println("Updated: " + deliveredItem.getName() + " → receivedQty = " + newTotal);
            }
        }

        if (totalUpdated > 0) {
            challanRepository.save(deliveredChallan);
        }

        return "Updated " + totalUpdated + " items in Delivered Challan: " + deliveredChallanNo;
    }
    
    private void applyInventoryEffects(Challan challan, boolean apply) {
        if (challan == null || challan.getItems() == null) return;
        Integer customerId = challan.getCustomer().getId();
        for (ChallanItem it : challan.getItems()) {
            Integer goodsId = it.getGoodsItemId();
            int qty = it.getDeliveredQty();
            int signedQty = challan.getChallanType() == ChallanType.DELIVERED
                ? (apply ? qty : -qty)
                : (apply ? -qty : qty);

            Optional<CustomerInventory> opt = customerInventoryRepository
                .findByCustomerIdAndGoodsItemId(customerId, goodsId);
            CustomerInventory ci = opt.orElse(new CustomerInventory());
            ci.setCustomerId(customerId);
            ci.setGoodsItemId(goodsId);
            ci.setQtyOnLoan(Math.max(ci.getQtyOnLoan() + signedQty, 0));
            ci.setLastUpdated(LocalDateTime.now());
            customerInventoryRepository.save(ci);
        }
    }

    @Override
    public ChallanDTO createChallan(ChallanDTO dto) {

//        Customer customer;
//
//        // Step 1: Handle missing customerId (0 = not set)
//        if (dto.getCustomerId() == 0) {
//            Customer newCust = new Customer();
//            newCust.setName(dto.getCustomerName());
//            newCust.setEmail(dto.getEmail());
//            newCust.setAddress(dto.getSiteLocation());
//            newCust.setContactNumber(dto.getContactNumber());
//            customer = customerRepository.save(newCust);
//            dto.setCustomerId(customer.getId()); // Update DTO for consistency
//        } else {
//            customer = customerRepository.findById(dto.getCustomerId())
//                .orElseThrow(() -> new CustomException("Customer not found: " + dto.getCustomerId(),HttpStatus.NOT_FOUND));
//        }

        Challan challan = dtoToEntity(dto);
    
        // Step 3: Generate challan number
        ApplicationSettings s = appSettingsRepository.findTopByOrderByIdAsc()
            .orElseGet(() -> {
                ApplicationSettings settings = new ApplicationSettings();
                settings.setInvoicePrefix("RCV-");
                settings.setChallanSequence(1);
                settings.setChallanSequenceResetPolicy("YEAR");
                return appSettingsRepository.save(settings);
            });
         
//        System.out.println(s);
        
        String challanNo;
        
        if(challan.getChallanType() == ChallanType.RECEIVED)
        {
        		challanNo =  "R-"+challan.getDeliveredChallanNo();
        }
        else
        {	
        		challanNo = "AUTO".equalsIgnoreCase(dto.getChallanNumber())
        				? newChallanNumberFormat(s, challan.getChallanType())
        						: dto.getChallanNumber();
        }
        
        challan.setChallanNumber(challanNo);
        appSettingsRepository.save(s);
        
        List<ChallanItem> newItems = dtoItemsToEntities(dto.getItems(), challan);
        
        if (challan.getChallanType() == ChallanType.RECEIVED && challan.getDeliveredChallanNo() != null) {
            int i = challanRepository.updateDeliveryReturnedAmount(challan.getDeliveredChallanNo(), challan.getReturnedAmount());
            System.out.println("Returned amount updated: " + i);
            
            // PASS DTO ITEMS — THEY HAVE THE ORIGINAL ID!
            updateDeliveredChallanItemsReceivedQuantity(challan.getDeliveredChallanNo(), dto.getItems());
        }
        	
        challan.setItems(newItems);
        Challan saved = challanRepository.save(challan);
        
        if(saved == null)
        {
        	throw new CustomException("Failed To Save Challan", HttpStatus.BAD_REQUEST);
        }
        
        applyInventoryEffects(saved, true);
        System.out.println(saved);

        ChallanDTO result = entityToDto(saved);
        result.setItems(entityItemsToDtos(saved.getItems()));
        return result;
    
    }

    @Override
    public ChallanDTO getChallanById(int id) {
        Challan challan = challanRepository.findByIdWithItems(id)
            .orElseThrow(() -> new CustomException("Challan not found: " + id,HttpStatus.NOT_FOUND));
        ChallanDTO dto = entityToDto(challan);
        dto.setItems(entityItemsToDtos(challan.getItems()));
        return dto;
    }

    @Override
    public List<ChallanDTO> getAllChallans() {
        return challanRepository.findAllWithItems().stream()
            .map(c -> { ChallanDTO d = entityToDto(c); d.setItems(entityItemsToDtos(c.getItems())); return d; })
            .collect(Collectors.toList());
    }

    @Override
    public ResponseEntity<String> updateChallan(int id, ChallanDTO dto) {
        Challan existing = challanRepository.findByIdWithItems(id)
                .orElseThrow(() -> new CustomException("Challan not found: " + id, HttpStatus.NOT_FOUND));

        applyInventoryEffects(existing, false);

        // === Update header fields only if changed ===
        if (dto.getCustomerId() != 0 && (existing.getCustomer() == null ||
                existing.getCustomer().getId() != dto.getCustomerId())) {
            Customer customer = customerRepository.findById(dto.getCustomerId())
                    .orElseThrow(() -> new CustomException("Customer not found", HttpStatus.NOT_FOUND));
            existing.setCustomer(customer);
        }

        if (!dto.getSiteLocation().equals(existing.getSiteLocation())) existing.setSiteLocation(dto.getSiteLocation());
        if (!dto.getVehicleNumber().equals(existing.getVehicleNumber())) existing.setVehicleNumber(dto.getVehicleNumber());
        if (!dto.getDriverName().equals(existing.getDriverName())) existing.setDriverName(dto.getDriverName());
        if (!dto.getTransporter().equals(existing.getTransporter())) existing.setTransporter(dto.getTransporter());
        if (!dto.getDriverNumber().equals(existing.getDriverNumber())) existing.setDriverNumber(dto.getDriverNumber());
        if (!dto.getDate().equals(existing.getDate())) existing.setDate(dto.getDate());
        if (!dto.getChallanType().equals(existing.getChallanType())) existing.setChallanType(dto.getChallanType());
        if (!dto.getDeliveryDetails().equals(existing.getDeliveryDetails())) existing.setDeliveryDetails(dto.getDeliveryDetails());
        existing.setPurchaseOrderNo(dto.getPurchaseOrderNo());
        existing.setDeposite(dto.getDeposite());
        if (!dto.getDepositeNarration().equals(existing.getDepositeNarration())) existing.setDepositeNarration(dto.getDepositeNarration());

        // deliveredChallanNo
        if (dto.getChallanType() == ChallanType.RECEIVED) {
            if (!dto.getDeliveredChallanNo().equals(existing.getDeliveredChallanNo())) {
                existing.setDeliveredChallanNo(dto.getDeliveredChallanNo());
                existing.setReturnedAmount(dto.getReturnedAmount());
            }
        } else {
            existing.setDeliveredChallanNo(null);
        }

        // === ITEMS UPDATE ===
        boolean isReceivedChallan = dto.getChallanType() == ChallanType.RECEIVED;

        if (dto.getItems() != null && !dto.getItems().isEmpty()) {
            List<ChallanItem> currentItems = existing.getItems();

            for (ChallanItemDTO dtoItem : dto.getItems()) {
                String[] newSrNo = dtoItem.getSrNo();
                boolean found = false;

                for (ChallanItem item : currentItems) {
                    if (Arrays.equals(item.getSrNo(), newSrNo)) {
                        found = true;

                        // Always update these
                        if (!dtoItem.getName().equals(item.getName())) item.setName(dtoItem.getName());
                        if (!dtoItem.getType().equals(item.getType())) item.setType(dtoItem.getType());
                        if (dtoItem.getDeliveredQty() != item.getDeliveredQty()) item.setDeliveredQty(dtoItem.getDeliveredQty());

                        // ONLY update receivedQty if challan is RECEIVED
                        if (isReceivedChallan && dtoItem.getReceivedQty() != item.getReceivedQty()) {
                            item.setReceivedQty(dtoItem.getReceivedQty());
                        }

                        if (dtoItem.getGoodsItemId() != null &&
                            !dtoItem.getGoodsItemId().equals(item.getGoodsItemId())) {
                            item.setGoodsItemId(dtoItem.getGoodsItemId());
                        }

                        // FULLY REPLACE srNo array if different
                        if (!Arrays.equals(item.getSrNo(), newSrNo)) {
                            item.setSrNo(newSrNo);
                        }

                        break;
                    }
                }

                // Add new item if not found
                if (!found) {
                    ChallanItem newItem = new ChallanItem();
                    newItem.setChallan(existing);
                    newItem.setName(dtoItem.getName());
                    newItem.setType(dtoItem.getType());
                    newItem.setDeliveredQty(dtoItem.getDeliveredQty());
                    newItem.setReceivedQty(isReceivedChallan ? dtoItem.getReceivedQty() : 0); // default 0 if DELIVERED
                    newItem.setSrNo(newSrNo);
                    newItem.setGoodsItemId(dtoItem.getGoodsItemId());
                    currentItems.add(newItem);
                }
            }

            // Remove deleted items
            currentItems.removeIf(item ->
                dto.getItems().stream()
                    .noneMatch(dtoItem -> Arrays.equals(dtoItem.getSrNo(), item.getSrNo()))
            );
        }

        Challan updated = challanRepository.save(existing);
        applyInventoryEffects(updated, true);

        return ResponseEntity.ok("Challan updated successfully. ID: " + updated.getId());
    }

    @Override
    public void deleteChallan(int id) {
        Challan challan = challanRepository.findById(id)
            .orElseThrow(() -> new CustomException("Challan not found: " + id,HttpStatus.NOT_FOUND));
        applyInventoryEffects(challan, false);
        challanRepository.delete(challan);
    }
    
    @Override
    @Transactional
    public ResponseEntity<String> deleteMultipleChallans(List<Integer> ids) {
        if (ids.isEmpty()) {
            return ResponseEntity.badRequest().body("No IDs provided");
        }

        int deleted = challanRepository.deleteChallansByIds(ids);

        return deleted > 0
            ? ResponseEntity.ok("Deleted " + deleted + " challan(s)")
            : ResponseEntity.notFound().build();
    }


    @Override
    public List<String> getChallanByCustomerId(int id) {

        // Step 1: Get only DELIVERED challan numbers for this customer
        List<String> deliveredChallanNumbers = challanRepository.findChallanByCustomerId(id);

        if (deliveredChallanNumbers.isEmpty()) {
            throw new CustomException("No delivered challans found for customer id: " + id, HttpStatus.NOT_FOUND);
        }

        // Step 2: Filter out fully returned challans (where every item is fully received)
        List<String> pendingChallanNumbers = deliveredChallanNumbers.stream()
            .filter(challanNo -> {
                // Fetch challan with items in one query
                Optional<Challan> challanOptional = challanRepository.findChallanByChallanNumberWithItems(challanNo);
                Challan challan = challanOptional.get();
                if (challan == null || challan.getItems() == null || challan.getItems().isEmpty()) {
                    return true; // keep if no items (safe)
                }

                // Keep only if AT LEAST ONE item has receivedQty < deliveredQty
                return challan.getItems().stream()
                    .anyMatch(item ->
                        item.getReceivedQty() == 0 ||
                        item.getReceivedQty() < item.getDeliveredQty()
                    );
            })
            .collect(Collectors.toList());

        if (pendingChallanNumbers.isEmpty()) {
            throw new CustomException(
                "All delivered challans for customer id " + id + " are fully returned. No pending challans.",
                HttpStatus.NOT_FOUND
            );
        }

        return pendingChallanNumbers;
    }
    
    @Override
    public ChallanDTO getChallanByChallanNumber(String challanNumber) {
    	
    	Challan challan = challanRepository.findChallanByChallanNumber(challanNumber);
    	
    	System.out.println(challan);
    	
    	if(challan == null)
    	{
    		throw new CustomException("Challan with Challan Number : "+challanNumber+" is not present", HttpStatus.NOT_FOUND);
    	}    	
    	return entityToDto(challan);
    }
    
    
    @Override
    public List<ChallanDTO> searchChallans(String name, String contactNumber, String email) {
        return challanRepository.searchChallans(name, contactNumber, email)
                .stream()
                .map(this::entityToDto)   // This method converts Customer → ChallanDTO
                .collect(Collectors.toList());
    }
    
    @Override
    public Page<ChallanDTO> getChallansPage(Pageable pageable) {
        return challanRepository.findAll(pageable)
            .map(this::entityToDto);
    }
    
}