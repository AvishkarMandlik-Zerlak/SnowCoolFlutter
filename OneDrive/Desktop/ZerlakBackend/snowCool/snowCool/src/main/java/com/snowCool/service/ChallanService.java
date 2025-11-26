package com.snowCool.service;

import com.snowCool.dto.ChallanDTO;
import com.snowCool.dto.ChallanItemDTO;
import com.snowCool.model.Challan;
import com.snowCool.model.ChallanItem;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;

public interface ChallanService {
    ChallanDTO createChallan(ChallanDTO challanDTO);
    ChallanDTO getChallanById(int id);
    List<ChallanDTO> getAllChallans();
    ResponseEntity<String> updateChallan(int id, ChallanDTO challanDTO);
    void deleteChallan(int id);
    ResponseEntity<String> deleteMultipleChallans(List<Integer> ids);
    ChallanDTO entityToDto(Challan challan);
    Challan dtoToEntity(ChallanDTO challan);
    List<ChallanItem> dtoItemsToEntities(List<ChallanItemDTO> dtos, Challan challan);
    List<ChallanItemDTO> entityItemsToDtos(List<ChallanItem> items);
    List<String> getChallanByCustomerId(int id);
    ChallanDTO getChallanByChallanNumber(String challanNumber);
    List<ChallanDTO> searchChallans(String name, String contactNumber, String email);
    Page<ChallanDTO> getChallansPage(Pageable pageable);
}
