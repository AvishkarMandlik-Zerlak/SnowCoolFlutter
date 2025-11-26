package com.snowCool.serviceImpl;

import com.snowCool.dto.ApplicationSettingsDTO;
import com.snowCool.model.ApplicationSettings;
import com.snowCool.repositories.ApplicationSettingsRepository;
import com.snowCool.service.ApplicationSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class ApplicationSettingsServiceImpl implements ApplicationSettingsService {

    @Autowired
    private ApplicationSettingsRepository repository;

    private ApplicationSettings dtoToEntity(ApplicationSettingsDTO dto, ApplicationSettings target) {
        if (target == null) target = new ApplicationSettings();
        target.setLogo(dto.getLogo());
        target.setInvoicePrefix(dto.getInvoicePrefix());
        target.setChallanNumberFormat(dto.getChallanNumberFormat());
        target.setChallanSequence(dto.getChallanSequence());
        target.setChallanSequenceResetPolicy(dto.getChallanSequenceResetPolicy());
        target.setSequenceLastResetDate(dto.getSequenceLastResetDate());
        target.setTermsAndConditions(dto.getTermsAndConditions());
        target.setSignature(dto.getSignature());
        return target;
    }

    private ApplicationSettingsDTO entityToDto(ApplicationSettings e) {
        ApplicationSettingsDTO dto = new ApplicationSettingsDTO();
        dto.setId(e.getId());
        dto.setLogo(e.getLogo());
        dto.setInvoicePrefix(e.getInvoicePrefix());
        dto.setChallanNumberFormat(e.getChallanNumberFormat());
        dto.setChallanSequence(e.getChallanSequence());
        dto.setChallanSequenceResetPolicy(e.getChallanSequenceResetPolicy());
        dto.setSequenceLastResetDate(e.getSequenceLastResetDate());
        dto.setCreatedAt(e.getCreatedAt());
        dto.setUpdatedAt(e.getUpdatedAt());
        dto.setSignature(e.getSignature());
        dto.setTermsAndConditions(e.getTermsAndConditions());
        return dto;
    }

    @Override
    public ApplicationSettingsDTO getSettings() {
        return repository.findTopByOrderByIdAsc()
                .map(this::entityToDto)
                .orElse(null);
    }

    @Override
    public ApplicationSettingsDTO createOrUpdateSettings(ApplicationSettingsDTO dto) {
        ApplicationSettings settings = repository.findTopByOrderByIdAsc().orElse(null);
        settings = dtoToEntity(dto, settings);
        ApplicationSettings saved = repository.save(settings);
        return entityToDto(saved);
    }
}
