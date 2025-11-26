package com.snowCool.serviceImpl;

import com.snowCool.dto.ProfileDTO;
import com.snowCool.model.Profile;
import com.snowCool.repositories.ProfileRepository;
import com.snowCool.service.ProfileService;
import com.snowCool.exception.CustomException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProfileServiceImpl implements ProfileService {
    @Autowired
    private ProfileRepository profileRepository;

    private Profile dtoToEntity(ProfileDTO dto) {
        Profile p = new Profile();
        p.setBusinessName(dto.getBusinessName());
        p.setDescription(dto.getDescription());
        p.setAddress(dto.getAddress());
        p.setMobileNumber(dto.getMobileNumber());
        p.setEmailId(dto.getEmailId());
        p.setTermsAndConditions(dto.getTermsAndConditions());
        // map logo filename if present in DTO
        if (dto.getLogoFileName() != null) {
            p.setLogoFileName(dto.getLogoFileName());
        }
        // map logo content type if provided
        if (dto.getLogoContentType() != null) {
            p.setLogoContentType(dto.getLogoContentType());
        }
        return p;
    }

    private ProfileDTO entityToDto(Profile p) {
        ProfileDTO dto = new ProfileDTO();
        dto.setId(p.getId());
        dto.setBusinessName(p.getBusinessName());
        dto.setDescription(p.getDescription());
        dto.setAddress(p.getAddress());
        dto.setMobileNumber(p.getMobileNumber());
        dto.setEmailId(p.getEmailId());
        dto.setTermsAndConditions(p.getTermsAndConditions());
        // map logo filename to DTO
        dto.setLogoFileName(p.getLogoFileName());
        // map logo content type to DTO
        dto.setLogoContentType(p.getLogoContentType());
        return dto;
    }

    @Override
    public ProfileDTO createProfile(ProfileDTO profileDTO) {
        Profile profile = dtoToEntity(profileDTO);
        Profile saved = profileRepository.save(profile);
        return entityToDto(saved);
    }

    @Override
    public ProfileDTO getProfileById(int id) {
        Profile profile = profileRepository.findById(id)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + id,HttpStatus.NOT_FOUND));
        return entityToDto(profile);
    }

    @Override
    public List<ProfileDTO> getAllProfiles() {
        return profileRepository.findAll().stream()
            .map(this::entityToDto)
            .collect(Collectors.toList());
    }

    @Override
    public ProfileDTO updateProfile(int id, ProfileDTO profileDTO) {
        Profile existing = profileRepository.findById(id)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + id,HttpStatus.NOT_FOUND));

        if (profileDTO.getBusinessName() != null && !profileDTO.getBusinessName().isBlank()) {
            existing.setBusinessName(profileDTO.getBusinessName().trim());
        }
        if (profileDTO.getDescription() != null && !profileDTO.getDescription().isBlank()) {
            existing.setDescription(profileDTO.getDescription().trim());
        }
        if (profileDTO.getAddress() != null && !profileDTO.getAddress().isBlank()) {
            existing.setAddress(profileDTO.getAddress().trim());
        }
        if (profileDTO.getMobileNumber() != null && !profileDTO.getMobileNumber().isBlank()) {
            existing.setMobileNumber(profileDTO.getMobileNumber().trim());
        }
        if (profileDTO.getEmailId() != null && !profileDTO.getEmailId().isBlank()) {
            existing.setEmailId(profileDTO.getEmailId().trim());
        }
        if (profileDTO.getTermsAndConditions() != null && !profileDTO.getTermsAndConditions().isBlank()) {
            existing.setTermsAndConditions(profileDTO.getTermsAndConditions().trim());
        }
        if (profileDTO.getLogoFileName() != null && !profileDTO.getLogoFileName().isBlank()) {
            existing.setLogoFileName(profileDTO.getLogoFileName().trim());
        }
        if (profileDTO.getLogoContentType() != null && !profileDTO.getLogoContentType().isBlank()) {
            existing.setLogoContentType(profileDTO.getLogoContentType().trim());
        }

        Profile updated = profileRepository.save(existing);
        return entityToDto(updated);
    }

    @Override
    public void deleteProfile(int id) {
        Profile existing = profileRepository.findById(id)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + id,HttpStatus.NOT_FOUND));
        profileRepository.delete(existing);
    }

    @Override
    public void updateTermsAndConditions(int profileId, String termsAndConditions) {
        Profile profile = profileRepository.findById(profileId)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + profileId,HttpStatus.NOT_FOUND));
        profile.setTermsAndConditions(termsAndConditions);
        profileRepository.save(profile);
    }
    

    @Override
    public void updateLogoFileName(int profileId, String logoFileName) {
        Profile profile = profileRepository.findById(profileId)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + profileId,HttpStatus.NOT_FOUND));
        profile.setLogoFileName(logoFileName);
        // controller enforces PNG-only uploads; set content type accordingly
        profile.setLogoContentType("image/png");
        profileRepository.save(profile);
    }

    // New: update logo with bytes and content type
    public void updateLogoWithBytes(int profileId, String logoFileName, String logoContentType, byte[] logoBytes) {
        Profile profile = profileRepository.findById(profileId)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + profileId,HttpStatus.NOT_FOUND));
        profile.setLogoFileName(logoFileName);
        profile.setLogoContentType(logoContentType);
        profile.setLogoBlob(logoBytes);
        profileRepository.save(profile);
    }

    @Override
    public String getLogoFileName(int profileId) {
        Profile profile = profileRepository.findById(profileId)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + profileId,HttpStatus.NOT_FOUND));
        return profile.getLogoFileName();
    }

    @Override
    public byte[] getLogoBytes(int profileId) {
        Profile profile = profileRepository.findById(profileId)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + profileId,HttpStatus.NOT_FOUND));
        return profile.getLogoBlob();
    }

    @Override
    public String getLogoContentType(int profileId) {
        Profile profile = profileRepository.findById(profileId)
            .orElseThrow(() -> new CustomException("Profile not found with id: " + profileId,HttpStatus.NOT_FOUND));
        return profile.getLogoContentType();
    }
}
