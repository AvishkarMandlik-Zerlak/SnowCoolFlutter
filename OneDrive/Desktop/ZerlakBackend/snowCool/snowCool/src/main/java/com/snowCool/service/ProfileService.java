package com.snowCool.service;

import com.snowCool.dto.ProfileDTO;
import java.util.List;

public interface ProfileService {
    ProfileDTO createProfile(ProfileDTO profileDTO);
    ProfileDTO getProfileById(int id);
    List<ProfileDTO> getAllProfiles();
    ProfileDTO updateProfile(int id, ProfileDTO profileDTO);
    void deleteProfile(int id);
    void updateTermsAndConditions(int profileId, String termsAndConditions);
    void updateLogoFileName(int profileId, String logoFileName);
    String getLogoFileName(int profileId);
    void updateLogoWithBytes(int profileId, String logoFileName, String logoContentType, byte[] logoBytes);

    // New: fetch logo bytes/content-type from DB
    byte[] getLogoBytes(int profileId);
    String getLogoContentType(int profileId);
}
