// src/main/java/com/snowCool/dto/ChallanDTO.java
package com.snowCool.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.snowCool.model.ChallanType;

import jakarta.persistence.Column;
import jakarta.validation.constraints.*;
import java.util.List;

public class ChallanDTO {

    private int id;

    private int customerId;

    @NotBlank(message = "Customer name required")
    @Pattern(regexp = "^[A-Za-z ]+$", message = "Only letters and spaces")
    private String customerName;

    @NotBlank(message = "Site location required")
    @Size(max = 100)
    private String siteLocation;

    @NotBlank(message = "Vehicle number required")
    @Pattern(regexp = "(^[A-Z]{2}[0-9]{1,2}[A-Z]{1,2}[0-9]{4}$)|(^[0-9]{2}BH[0-9]{4}[A-Z]{1,2}$)")
    private String vehicleNumber;
    
    private String deliveredChallanNo;

    @NotBlank(message = "Driver name required")
    @Pattern(regexp = "^[A-Za-z ]+$")
    private String driverName;

    @NotBlank(message = "Driver number required")
    @Pattern(regexp = "^[0-9]{10}$")
    private String driverNumber;

    @NotBlank(message = "Transporter required")
    @Size(max = 50)
    private String transporter;

    @NotBlank(message = "Challan number required")
    private String challanNumber = "AUTO";  // DEFAULT AUTO

    @NotNull(message = "Items required")
    @Size(min = 1, message = "At least one item")
    private List<ChallanItemDTO> items;

    @NotNull(message = "Challan type required")
    private ChallanType challanType = ChallanType.RECEIVED;

    @NotBlank(message = "Date is required")
    @Pattern(regexp = "^\\d{4}-\\d{2}-\\d{2}$", message = "Format: yyyy-MM-dd")
    private String date;
    
    private String purchaseOrderNo;
    
    private double deposite;
    
    private double returnedAmount;
    
    private String depositeNarration;
    
    private String deliveryDetails;
    
	// Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public int getCustomerId() { return customerId; }
    public void setCustomerId(int customerId) { this.customerId = customerId; }
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    public String getSiteLocation() { return siteLocation; }
    public void setSiteLocation(String siteLocation) { this.siteLocation = siteLocation; }
    public String getVehicleNumber() { return vehicleNumber; }
    public void setVehicleNumber(String vehicleNumber) { this.vehicleNumber = vehicleNumber; }
    public String getDriverName() { return driverName; }
    public void setDriverName(String driverName) { this.driverName = driverName; }
    public String getDriverNumber() { return driverNumber; }
    public void setDriverNumber(String driverNumber) { this.driverNumber = driverNumber; }
    public String getTransporter() { return transporter; }
    public void setTransporter(String transporter) { this.transporter = transporter; }
    public String getChallanNumber() { return challanNumber; }
    public void setChallanNumber(String challanNumber) { this.challanNumber = challanNumber; }
    public List<ChallanItemDTO> getItems() { return items; }
    public void setItems(List<ChallanItemDTO> items) { this.items = items; }
    public ChallanType getChallanType() { return challanType; }
    public void setChallanType(ChallanType challanType) { this.challanType = challanType; }
    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }
    public String getPurchaseOrderNo() {return purchaseOrderNo;}
  	public void setPurchaseOrderNo(String email) {this.purchaseOrderNo = email;}
  	public double getDeposite() {return deposite;}
  	public void setDeposite(double deposite) {this.deposite = deposite;}
  	public String getDepositeNarration() { return depositeNarration;}
  	public void setDepositeNarration(String depositeNarration) {this.depositeNarration = depositeNarration;}
    public String getDeliveryDetails() { return deliveryDetails; }
    public void setDeliveryDetails(String deliveryDetails) { this.deliveryDetails = deliveryDetails; }
	public String getDeliveredChallanNo() {return deliveredChallanNo;}
	public void setDeliveredChallanNo(String deliveredChallanNo) {this.deliveredChallanNo = deliveredChallanNo;}
	public double getReturnedAmount() {return returnedAmount;}
	public void setReturnedAmount(double returnedAmount) {this.returnedAmount = returnedAmount;}
	@Override
	public String toString() {
		return "ChallanDTO [id=" + id + ", customerId=" + customerId + ", customerName=" + customerName
				+ ", siteLocation=" + siteLocation + ", vehicleNumber=" + vehicleNumber + ", driverName=" + driverName
				+ ", driverNumber=" + driverNumber + ", transporter=" + transporter + ", challanNumber=" + challanNumber
				+ ", items=" + items + ", challanType=" + challanType + ", date=" + date + ", purchaseOrderNo="
				+ purchaseOrderNo + ", deposite=" + deposite + ", depositeNarration=" + depositeNarration
				+ ", deliveryDetails=" + deliveryDetails + "]";
	}
    
    
}