// src/main/java/com/snowCool/model/Customer.java
package com.snowCool.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.Id;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import java.util.List;

import com.snowCool.dto.ChallanItemDTO;

import jakarta.persistence.OneToMany;
import jakarta.persistence.FetchType;

@Entity
@Table(name = "customer")
public class Customer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    private String name;
    private String address;
    private String contactNumber;
    private String email;
    private String reminder;
    private double openingBalance;

    @OneToMany(mappedBy = "customer", fetch = FetchType.LAZY)
    private List<Challan> challans;

    public Customer() {}
    public Customer(int id, String name, String address, String contactNumber, String email) {
        this.id = id;
        this.name = name;
        this.address = address;
        this.contactNumber = contactNumber;
        this.email = email;
    }

    // Getters and setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getContactNumber() { return contactNumber; }
    public void setContactNumber(String contactNumber) { this.contactNumber = contactNumber; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public List<Challan> getChallans() { return challans; }
    public void setChallans(List<Challan> challans) { this.challans = challans; }
     
   	public String getReminder() {return reminder;}
   	public void setReminder(String reminder) {this.reminder = reminder;}
   	
   	public double getOpeningBalance() {return openingBalance;}
   	public void setOpeningBalance(double openingBalance) {this.openingBalance = openingBalance;}
   	
}