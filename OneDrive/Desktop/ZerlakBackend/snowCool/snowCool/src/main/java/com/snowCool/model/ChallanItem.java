package com.snowCool.model;

import jakarta.persistence.*;

@Entity
@Table(name = "challan_item")
public class ChallanItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne
    private Challan challan;

    private String name;
    private int deliveredQty;
    private int receivedQty;
    private String[] srNo;

    @Column(name = "goods_item_id")
    private Integer goodsItemId;

    private String type;

    public ChallanItem() {
    }

    

    public ChallanItem(int id, Challan challan, String name, int deliveredQty, int receivedQty, String[] srNo,
			Integer goodsItemId, String type) {
		super();
		this.id = id;
		this.challan = challan;
		this.name = name;
		this.deliveredQty = deliveredQty;
		this.receivedQty = receivedQty;
		this.srNo = srNo;
		this.goodsItemId = goodsItemId;
		this.type = type;
	}



	public int getId() {
		return id;
	}



	public void setId(int id) {
		this.id = id;
	}



	public Challan getChallan() {
		return challan;
	}



	public void setChallan(Challan challan) {
		this.challan = challan;
	}



	public String getName() {
		return name;
	}



	public void setName(String name) {
		this.name = name;
	}



	public int getDeliveredQty() {
		return deliveredQty;
	}



	public void setDeliveredQty(int deliveredQty) {
		this.deliveredQty = deliveredQty;
	}



	public int getReceivedQty() {
		return receivedQty;
	}



	public void setReceivedQty(int receivedQty) {
		this.receivedQty = receivedQty;
	}



	public String[] getSrNo() {
		return srNo;
	}



	public void setSrNo(String[] srNo) {
		this.srNo = srNo;
	}



	public Integer getGoodsItemId() {
		return goodsItemId;
	}



	public void setGoodsItemId(Integer goodsItemId) {
		this.goodsItemId = goodsItemId;
	}


	public String getType() {
		return type;
	}
	public void setType(String type) {
		this.type = type;
	}
	// Getters and setters
   
}
