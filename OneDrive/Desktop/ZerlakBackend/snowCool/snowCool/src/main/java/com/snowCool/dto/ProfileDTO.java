package com.snowCool.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;

public class ProfileDTO {
    private int id;
    @JsonAlias({"businessName", "business name", "company", "name"})
    @JsonProperty("name")
    private String businessName;
    @JsonAlias({"description", "company"})
    @JsonProperty("company")
    private String description;
    @JsonProperty("address")
    private String address;
    @JsonAlias({"mobileNumber", "phone", "mobile", "contactNumber"})
    @JsonProperty("phone")
    private String mobileNumber;
    @JsonAlias({"emailId", "email", "emailID"})
    @JsonProperty("email")
    private String emailId;
    private String termsAndConditions;

    // filename for uploaded logo (optional)
    private String logoFileName;

    // optional content type for logo (e.g. image/png)
    private String logoContentType;

    // Getters and setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getBusinessName() { return businessName; }
    public void setBusinessName(String businessName) {
        if (businessName != null && !businessName.isBlank()) {
            this.businessName = businessName.trim();
        }
    }
    public String getDescription() { return description; }
    public void setDescription(String description) {
        if (description != null && !description.isBlank()) {
            this.description = description.trim();
        }
    }
    public String getAddress() { return address; }
    public void setAddress(String address) {
        if (address != null && !address.isBlank()) {
            this.address = address.trim();
        }
    }
    public String getMobileNumber() { return mobileNumber; }
    public void setMobileNumber(String mobileNumber) {
        if (mobileNumber != null && !mobileNumber.isBlank()) {
            this.mobileNumber = mobileNumber.trim();
        }
    }
    public String getEmailId() { return emailId; }
    public void setEmailId(String emailId) {
        if (emailId != null && !emailId.isBlank()) {
            this.emailId = emailId.trim();
        }
    }
    public String getTermsAndConditions() { return termsAndConditions; }
    public void setTermsAndConditions(String termsAndConditions) {
        if (termsAndConditions != null && !termsAndConditions.isBlank()) {
            this.termsAndConditions = termsAndConditions.trim();
        }
    }

    public String getLogoFileName() { return logoFileName; }
    public void setLogoFileName(String logoFileName) {
        if (logoFileName != null && !logoFileName.isBlank()) {
            this.logoFileName = logoFileName.trim();
        }
    }

    public String getLogoContentType() { return logoContentType; }
    public void setLogoContentType(String logoContentType) {
        if (logoContentType != null && !logoContentType.isBlank()) {
            this.logoContentType = logoContentType.trim();
        }
    }

    // convenience
    public boolean isLogoUploaded() {
        return this.logoFileName != null && !this.logoFileName.isBlank();
    }
}
