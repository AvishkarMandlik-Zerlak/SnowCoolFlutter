package com.snowCool.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "username", unique = true)
    private String username;

    @Column(name = "password")
    private String password;

    @Column(name = "role")
    private String role;

    @Column(name = "active")
    private Boolean active;

    // Permissions for employee-level fine-grained access
    @Column(name = "can_create_customer")
    private Boolean canCreateCustomer;

    @Column(name = "can_manage_goods_items")
    private Boolean canManageGoodsItems;

    @Column(name = "can_manage_challans")
    private Boolean canManageChallans;

    @Column(name = "can_manage_profiles")
    private Boolean canManageProfiles;

    @Column(name = "can_manage_settings")
    private Boolean canManageSettings;
    
    @Column(name = "can_manage_passbook")
    private Boolean canManagePassbook;

    public User() {}

    public User(Long id, String username, String password, String role) {
        this.id = id;
        this.username = username;
        this.password = password;
        this.role = role;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }

    public Boolean getCanCreateCustomer() { return canCreateCustomer; }
    public void setCanCreateCustomer(Boolean canCreateCustomer) { this.canCreateCustomer = canCreateCustomer; }

    public Boolean getCanManageGoodsItems() { return canManageGoodsItems; }
    public void setCanManageGoodsItems(Boolean canManageGoodsItems) { this.canManageGoodsItems = canManageGoodsItems; }

    public Boolean getCanManageChallans() { return canManageChallans; }
    public void setCanManageChallans(Boolean canManageChallans) { this.canManageChallans = canManageChallans; }

    public Boolean getCanManageProfiles() { return canManageProfiles; }
    public void setCanManageProfiles(Boolean canManageProfiles) { this.canManageProfiles = canManageProfiles; }

    public Boolean getCanManageSettings() { return canManageSettings; }
    public void setCanManageSettings(Boolean canManageSettings) { this.canManageSettings = canManageSettings; }
    
    public Boolean getCanManagePassbook() {return canManagePassbook;}
	public void setCanManagePassbook(Boolean canManagePassbook) {this.canManagePassbook = canManagePassbook;}

	@Override
	public String toString() {
		return "User [id=" + id + ", username=" + username + ", password=" + password + ", role=" + role + ", active="
				+ active + ", canCreateCustomer=" + canCreateCustomer + ", canManageGoodsItems=" + canManageGoodsItems
				+ ", canManageChallans=" + canManageChallans + ", canManageProfiles=" + canManageProfiles
				+ ", canManageSettings=" + canManageSettings + "]";
	}
    
    
}
