// src/main/java/com/snowCool/model/Challan.java
package com.snowCool.model;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "challan")
public class Challan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne
    @JoinColumn(name = "customer_id")
    private Customer customer;

    @Column(name = "site_location")
    private String siteLocation;

    @Column(name = "vehicle_number")
    private String vehicleNumber;

    @Column(name = "driver_name")
    private String driverName;
    
    @Column(name = "delivered_challan_no")
    private String deliveredChallanNo;

    @Column(name = "driver_phone_no")
    private String driverNumber;

    @Column(name = "transporter")
    private String transporter;

    @Column(name = "challan_number")
    private String challanNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "challan_type")
    private ChallanType challanType;

    @OneToMany(
    	    cascade = CascadeType.ALL,
    	    orphanRemoval = true,
    	    fetch = FetchType.EAGER
    	)
    	private List<ChallanItem> items = new ArrayList<ChallanItem>();

    private String deliveryDetails;
    
    private double returnedAmount;

    @Column(name = "date")  // String in DB
    private String date;
    
    private String purchaseOrderNo;
    
    private double deposite;
    
    private String depositeNarration;

    // Constructors
    public Challan() {}

	// Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public Customer getCustomer() { return customer; }
    public void setCustomer(Customer customer) { this.customer = customer; }
    public String getSiteLocation() { return siteLocation; }
    public void setSiteLocation(String siteLocation) { this.siteLocation = siteLocation; }
    public String getVehicleNumber() { return vehicleNumber; }
    public void setVehicleNumber(String vehicleNumber) { this.vehicleNumber = vehicleNumber; }
    public String getDriverName() { return driverName; }
    public void setDriverName(String driverName) { this.driverName = driverName; }
    public String getTransporter() { return transporter; }
    public void setTransporter(String transporter) { this.transporter = transporter; }
    public String getChallanNumber() { return challanNumber; }
    public void setChallanNumber(String challanNumber) { this.challanNumber = challanNumber; }
    public ChallanType getChallanType() { return challanType; }
    public void setChallanType(ChallanType challanType) { this.challanType = challanType; }
    public List<ChallanItem> getItems() { return items; }
    public void setItems(List<ChallanItem> items) {
        this.items = items;
        if (items != null) {
            items.forEach(item -> item.setChallan(this));
        }
    }
    public String getDeliveryDetails() { return deliveryDetails; }
    public void setDeliveryDetails(String deliveryDetails) { this.deliveryDetails = deliveryDetails; }

    public String getDriverNumber() { return driverNumber; }
    public void setDriverNumber(String driverNumber) { this.driverNumber = driverNumber; }
    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }

    public String getPurchaseOrderNo() {return purchaseOrderNo;}
	public void setPurchaseOrderNo(String email) {this.purchaseOrderNo = email;}

	public double getDeposite() {return deposite;}
	public void setDeposite(double deposite) {this.deposite = deposite;}

	public String getDepositeNarration() { return depositeNarration;}
	public void setDepositeNarration(String depositeNarration) {this.depositeNarration = depositeNarration;}

	public String getDeliveredChallanNo() {return deliveredChallanNo;}
	public void setDeliveredChallanNo(String deliveredChallanNo) {this.deliveredChallanNo = deliveredChallanNo;}

	public double getReturnedAmount() {return returnedAmount;}
	public void setReturnedAmount(double returnedAmount) {this.returnedAmount = returnedAmount;}

	@Override
	public String toString() {
		return "Challan [id=" + id + ", customer=" + customer + ", siteLocation=" + siteLocation + ", vehicleNumber="
				+ vehicleNumber + ", driverName=" + driverName + ", driverNumber=" + driverNumber + ", transporter="
				+ transporter + ", challanNumber=" + challanNumber + ", challanType=" + challanType + ", items=" + items
				+ ", deliveryDetails=" + deliveryDetails + ", date=" + date + ", purchaseOrderNo=" + purchaseOrderNo
				+ ", deposite=" + deposite + ", depositeNarration=" + depositeNarration + "]";
	}
	
}