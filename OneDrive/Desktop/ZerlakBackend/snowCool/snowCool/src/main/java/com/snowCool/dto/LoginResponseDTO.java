package com.snowCool.dto;

public class LoginResponseDTO {
	
	private Long id ;
    private String token;
    private String role;
    private Boolean canCreateCustomers;
    private Boolean canManageGoodsItems;
    private Boolean canManageChallans;
    private Boolean canManageProfiles;
    private Boolean canManageSettings;
    private Boolean canManagePassbook;
    
	// Getters and setters
    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public Long getId() {return id;}
  	public void setId(Long id) {this.id = id;}
	public Boolean getCanCreateCustomers() {return canCreateCustomers;}
	public void setCanCreateCustomers(Boolean canCreateCustomers) {this.canCreateCustomers = canCreateCustomers;}
	public Boolean getCanManageGoodsItems() {return canManageGoodsItems;}
	public void setCanManageGoodsItems(Boolean canManageGoodsItems) {this.canManageGoodsItems = canManageGoodsItems;}
	public Boolean getCanManageChallans() {return canManageChallans;}
	public void setCanManageChallans(Boolean canManageChallans) {this.canManageChallans = canManageChallans;}
	public Boolean getCanManageProfiles() {return canManageProfiles;}
	public void setCanManageProfiles(Boolean canManageProfiles) {this.canManageProfiles = canManageProfiles;}
	public Boolean getCanManageSettings() {return canManageSettings;}
	public void setCanManageSettings(Boolean canManageSettings) {this.canManageSettings = canManageSettings;}
	public Boolean getCanManagePassbook() {return canManagePassbook;}
	public void setCanManagePassbook(Boolean canManagePassbook) {this.canManagePassbook = canManagePassbook;}
  	
}

