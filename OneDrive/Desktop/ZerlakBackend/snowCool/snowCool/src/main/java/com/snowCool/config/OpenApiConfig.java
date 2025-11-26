package com.snowCool.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springdoc.core.models.GroupedOpenApi;

@Configuration
@OpenAPIDefinition(
    info = @Info(title = "SnowCool API", version = "v1", description = "SnowCool Inventory APIs"),
    servers = {@Server(url = "/", description = "Default Server")}
//    security = {@SecurityRequirement(name = "bearerAuth")}
    
)

public class OpenApiConfig {
    @Bean
    public GroupedOpenApi publicApi() {
        return GroupedOpenApi.builder()
            .group("v1")
            .packagesToScan("com.snowCool.controller")
            .pathsToMatch("/api/**")
            .build();
    }
}
