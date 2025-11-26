package com.snowCool.dto;

public class ChallanItemDTO {
	
	private int id;
    private String name;
    private int deliveredQty;
    private int receivedQty;
    private String[] srNo;
    // New fields for batch-mode inventory
    private Integer goodsItemId; // optional FK to goods_items
    private String type;

    
    // Getters and setters
    
    public int getId() {return id;}
	public void setId(int id) {this.id = id;}
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String[] getSrNo() { return srNo; }
    public void setSrNo(String[] srNo) { this.srNo = srNo; }

    public Integer getGoodsItemId() { return goodsItemId; }
    public void setGoodsItemId(Integer goodsItemId) { this.goodsItemId = goodsItemId; }
	
    public String getType() {return type;}
	public void setType(String type) {this.type = type;}
	public int getDeliveredQty() {return deliveredQty;}
	public void setDeliveredQty(int deliveredQty) {this.deliveredQty = deliveredQty;}
	public int getReceivedQty() {return receivedQty;}
	public void setReceivedQty(int receivedQty) {this.receivedQty = receivedQty;}
	
	
	
}
