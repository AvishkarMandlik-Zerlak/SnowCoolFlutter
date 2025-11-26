package com.snowCool.dto;

import java.util.List;

public class CustomerDTO {
	
	private int id;
	private String name;
    private String address;
    private String contactNumber;
    private String email;
    private String reminder;
    private double deposite;
    private List<ChallanItemDTO> items;

    // Getters and setters
    public int getId() {return id;}
  	public void setId(int id) {this.id = id;}
  	
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getContactNumber() { return contactNumber; }
    public void setContactNumber(String contactNumber) { this.contactNumber = contactNumber; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
	public String getReminder() {return reminder;}
	public void setReminder(String reminder) {this.reminder = reminder;}
	
	public double getDeposite() {return deposite;}
	public void setDeposite(double deposit) {this.deposite = deposit;}
	
	public List<ChallanItemDTO> getItems() {return items;}
	public void setItems(List<ChallanItemDTO> items) {this.items = items;}
    
    
}

