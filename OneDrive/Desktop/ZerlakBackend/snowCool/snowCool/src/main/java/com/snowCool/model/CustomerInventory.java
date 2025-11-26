package com.snowCool.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "customer_inventory", uniqueConstraints = @UniqueConstraint(columnNames = {"customer_id","goods_item_id","batch_ref"}))
public class CustomerInventory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "customer_id", nullable = false)
    private Integer customerId;

    @Column(name = "goods_item_id")
    private Integer goodsItemId;

    @Column(name = "qty_on_loan", nullable = false)
    private Integer qtyOnLoan = 0;

    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;

    public CustomerInventory() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getCustomerId() { return customerId; }
    public void setCustomerId(Integer customerId) { this.customerId = customerId; }

    public Integer getGoodsItemId() { return goodsItemId; }
    public void setGoodsItemId(Integer goodsItemId) { this.goodsItemId = goodsItemId; }

    public Integer getQtyOnLoan() { return qtyOnLoan; }
    public void setQtyOnLoan(Integer qtyOnLoan) { this.qtyOnLoan = qtyOnLoan; }

    public LocalDateTime getLastUpdated() { return lastUpdated; }
    public void setLastUpdated(LocalDateTime lastUpdated) { this.lastUpdated = lastUpdated; }
}

