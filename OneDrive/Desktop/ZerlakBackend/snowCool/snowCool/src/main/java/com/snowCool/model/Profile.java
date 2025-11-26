// src/main/java/com/snowCool/model/Profile.java
package com.snowCool.model;

import jakarta.persistence.*;

@Entity
@Table(name = "profile")
public class Profile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    private String businessName;
    private String description;
    private String address;
    private String mobileNumber;
    private String emailId;
    @Column(length = 4000)
    private String termsAndConditions;

    // new field to store the filename (or path fragment) of the uploaded logo
    @Column(name = "logo_file_name", length = 255)
    private String logoFileName;

    // optional: store content type of the logo (e.g. image/png)
    @Column(name = "logo_content_type", length = 100)
    private String logoContentType;

    // optional: store binary data for the logo inside the DB (LONGBLOB for MySQL)
    @Lob
    @Basic(fetch = FetchType.LAZY)
    @Column(name = "logo_blob", columnDefinition = "LONGBLOB")
    private byte[] logoBlob;

    public Profile() {
    }

    public Profile(Integer id, String businessName, String description, String address, String mobileNumber, String emailId, String termsAndConditions) {
        this.id = id;
        this.businessName = businessName;
        this.description = description;
        this.address = address;
        this.mobileNumber = mobileNumber;
        this.emailId = emailId;
        this.termsAndConditions = termsAndConditions;
    }

    // overloaded constructor that accepts logo filename
    public Profile(Integer id, String businessName, String description, String address, String mobileNumber, String emailId, String termsAndConditions, String logoFileName) {
        this(id, businessName, description, address, mobileNumber, emailId, termsAndConditions);
        this.logoFileName = logoFileName;
    }

    // Getters and setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public String getBusinessName() { return businessName; }
    public void setBusinessName(String businessName) { this.businessName = businessName; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getMobileNumber() { return mobileNumber; }
    public void setMobileNumber(String mobileNumber) { this.mobileNumber = mobileNumber; }
    public String getEmailId() { return emailId; }
    public void setEmailId(String emailId) { this.emailId = emailId; }
    public String getTermsAndConditions() { return termsAndConditions; }
    public void setTermsAndConditions(String termsAndConditions) { this.termsAndConditions = termsAndConditions; }

    // Getter/setter for logoFileName
    public String getLogoFileName() { return logoFileName; }
    public void setLogoFileName(String logoFileName) { this.logoFileName = logoFileName; }

    // Getter/setter for logoContentType
    public String getLogoContentType() { return logoContentType; }
    public void setLogoContentType(String logoContentType) { this.logoContentType = logoContentType; }

    // Getter/setter for logoBlob
    public byte[] getLogoBlob() { return logoBlob; }
    public void setLogoBlob(byte[] logoBlob) { this.logoBlob = logoBlob; }

    // Transient helper - not persisted: indicates if a logo has been uploaded
    @Transient
    public boolean isLogoUploaded() {
        return (this.logoFileName != null && !this.logoFileName.isBlank()) || (this.logoBlob != null && this.logoBlob.length > 0);
    }
}