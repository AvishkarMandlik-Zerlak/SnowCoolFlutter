package com.snowCool.serviceImpl;

import com.snowCool.model.GoodsItems;
import com.snowCool.repositories.GoodsItemsRepository;
import com.snowCool.service.GoodsItemsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class GoodsItemsServiceImpl implements GoodsItemsService {
    @Autowired
    private GoodsItemsRepository goodsItemsRepository;

    @Override
    public GoodsItems createGoodsItem(GoodsItems item) {
        return goodsItemsRepository.save(item);
    }

    @Override
    public GoodsItems getGoodsItem(int id) {
        return goodsItemsRepository.findById(id).orElse(null);
    }

    @Override
    public List<GoodsItems> getAllGoodsItems() {
        return goodsItemsRepository.findAll();
    }

    @Override
    public GoodsItems updateGoodsItem(int id, GoodsItems item) {
        Optional<GoodsItems> existing = goodsItemsRepository.findById(id);
        if (existing.isPresent()) {
            GoodsItems goodsItem = existing.get();
            goodsItem.setName(item.getName());
            return goodsItemsRepository.save(goodsItem);
        }
        return null;
    }

    @Override
    public void deleteGoodsItem(int id) {
        goodsItemsRepository.deleteById(id);
    }
}
