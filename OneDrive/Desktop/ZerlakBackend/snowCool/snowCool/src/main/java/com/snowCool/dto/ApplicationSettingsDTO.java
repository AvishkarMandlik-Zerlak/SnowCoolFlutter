package com.snowCool.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class ApplicationSettingsDTO {

    private Integer id;
    private byte[] logo;         // actual image bytes
    private byte[] signature;    // actual image bytes
    private String invoicePrefix;
    private String challanNumberFormat;
    private Integer challanSequence;
    private String challanSequenceResetPolicy;
    private LocalDate sequenceLastResetDate;
    private String termsAndConditions;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // ===== Getters and Setters =====
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public byte[] getLogo() { return logo; }
    public void setLogo(byte[] logo) { this.logo = logo; }

    public byte[] getSignature() { return signature; }
    public void setSignature(byte[] signature) { this.signature = signature; }

    public String getInvoicePrefix() { return invoicePrefix; }
    public void setInvoicePrefix(String invoicePrefix) { this.invoicePrefix = invoicePrefix; }

    public String getChallanNumberFormat() { return challanNumberFormat; }
    public void setChallanNumberFormat(String challanNumberFormat) { this.challanNumberFormat = challanNumberFormat; }

    public Integer getChallanSequence() { return challanSequence; }
    public void setChallanSequence(Integer challanSequence) { this.challanSequence = challanSequence; }

    public String getChallanSequenceResetPolicy() { return challanSequenceResetPolicy; }
    public void setChallanSequenceResetPolicy(String challanSequenceResetPolicy) { this.challanSequenceResetPolicy = challanSequenceResetPolicy; }

    public LocalDate getSequenceLastResetDate() { return sequenceLastResetDate; }
    public void setSequenceLastResetDate(LocalDate sequenceLastResetDate) { this.sequenceLastResetDate = sequenceLastResetDate; }

    public String getTermsAndConditions() { return termsAndConditions; }
    public void setTermsAndConditions(String termsAndConditions) { this.termsAndConditions = termsAndConditions; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
