package com.snowCool.service;

import com.snowCool.model.GoodsItems;
import java.util.List;

public interface GoodsItemsService {
    GoodsItems createGoodsItem(GoodsItems item);
    GoodsItems getGoodsItem(int id);
    List<GoodsItems> getAllGoodsItems();
    GoodsItems updateGoodsItem(int id, GoodsItems item);
    void deleteGoodsItem(int id);
}
