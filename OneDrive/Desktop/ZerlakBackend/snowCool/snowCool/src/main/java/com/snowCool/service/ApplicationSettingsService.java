package com.snowCool.service;

import com.snowCool.dto.ApplicationSettingsDTO;

public interface ApplicationSettingsService {
    ApplicationSettingsDTO getSettings();
    ApplicationSettingsDTO createOrUpdateSettings(ApplicationSettingsDTO dto);
}

