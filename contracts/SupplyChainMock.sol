// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SupplyChain.sol";

contract SupplyChainMock is SupplyChain {
    function addItem(string memory _name, uint _price, address _seller) public returns (bool) {
        require(bytes(_name).length != 0, "No name was received");
        require(_price > 0, "No price was received");

        Item memory newItem = Item({
        name: _name,
        sku: skuCount,
        price: _price,
        state: State.ForSale,
        seller: payable(_seller),
        buyer: payable(address(0))
        });

        items[skuCount] = newItem;
        
        skuCount++;
        
        emit LogForSale(skuCount - 1);

        return true;
    }

    function buyItem(uint _sku, address _buyer) public payable forSale(_sku) paidEnough(items[_sku].price) checkValue(_sku) {
        require(_buyer != address(0), "Buy Item: Zero address");

        Item memory item = items[_sku];
        
        item.seller.transfer(item.price);

        item.buyer = payable(_buyer);
        item.state = State.Sold;

        items[_sku] = item;

        emit LogSold(_sku);
    }
}