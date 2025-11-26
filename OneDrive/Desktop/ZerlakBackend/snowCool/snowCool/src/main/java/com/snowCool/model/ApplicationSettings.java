package com.snowCool.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Base64;

@Entity
@Table(name = "application_settings")
public class ApplicationSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // Store images as MEDIUMBLOBs in DB
    @Lob
    @Column(name = "logo_blob", columnDefinition = "MEDIUMBLOB")
    private byte[] logo; // logo image bytes

    @Lob
    @Column(name = "signature_blob", columnDefinition = "MEDIUMBLOB")
    private byte[] signature; // signature image bytes

    private String invoicePrefix;

    private String challanNumberFormat; // e.g., CH-{YYYY}-{SEQ:5}
    private Integer challanSequence;    
    private String challanSequenceResetPolicy; // NONE, YEAR, MONTH, DAY
    private LocalDate sequenceLastResetDate;

    @Column(columnDefinition = "TEXT")
    private String termsAndConditions;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // ===== Lifecycle Hooks =====
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = createdAt;
        if (challanSequence == null) challanSequence = 1;
        if (challanSequenceResetPolicy == null) challanSequenceResetPolicy = "NONE";
        if (sequenceLastResetDate == null) sequenceLastResetDate = LocalDate.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

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

    // ===== NEW: Base64 helpers for PDF or Flutter compatibility =====
    public String getLogoBase64() {
        if (logo == null || logo.length == 0) return null;
        return Base64.getEncoder().encodeToString(logo);
    }

    public String getSignatureBase64() {
        if (signature == null || signature.length == 0) return null;
        return Base64.getEncoder().encodeToString(signature);
    }

    public void setLogoBase64(String base64) {
        if (base64 == null || base64.isEmpty()) {
            this.logo = null;
        } else {
            this.logo = Base64.getDecoder().decode(base64);
        }
    }

    public void setSignatureBase64(String base64) {
        if (base64 == null || base64.isEmpty()) {
            this.signature = null;
        } else {
            this.signature = Base64.getDecoder().decode(base64);
        }
    }

	@Override
	public String toString() {
		return "ApplicationSettings [id=" + id + ", logo=" + Arrays.toString(logo) + ", signature="
				+ Arrays.toString(signature) + ", invoicePrefix=" + invoicePrefix + ", challanNumberFormat="
				+ challanNumberFormat + ", challanSequence=" + challanSequence + ", challanSequenceResetPolicy="
				+ challanSequenceResetPolicy + ", sequenceLastResetDate=" + sequenceLastResetDate
				+ ", termsAndConditions=" + termsAndConditions + ", createdAt=" + createdAt + ", updatedAt=" + updatedAt
				+ "]";
	}
    
    
}
