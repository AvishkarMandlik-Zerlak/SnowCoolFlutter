package com.snowCool.repositories;

import com.snowCool.model.ApplicationSettings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ApplicationSettingsRepository extends JpaRepository<ApplicationSettings, Integer> {
    Optional<ApplicationSettings> findTopByOrderByIdAsc();
}

