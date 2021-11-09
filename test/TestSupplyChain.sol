// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChainMock.sol";
//supply_chain.test
contract TestSupplyChainMock {
    uint public initialBalance = 80 ether;
    SupplyChainMock private sp;

    function beforeEach() public {
        sp = new SupplyChainMock();
        sp.addItem("Test Item", 100, msg.sender);
    }

    //c addItem
    function testAddItem() public {
        (string memory name, uint sku, uint price, uint state, address seller, address buyer) = sp.fetchItem(0);

        Assert.equal(seller, msg.sender, "Seller is incorrect ");
        Assert.equal(name, "Test Item", "Name is incorrect");
        Assert.equal(sku, 0, "Sku is incorrect");
        Assert.equal(price, 100, "Price is incorrect");
        Assert.equal(state, 0, "State is incorrect");
        Assert.equal(buyer, address(0), "Buyer is incorrect");
    }

    //r buyItem
    function testBuy() public {
        sp.buyItem{value: 100}(0, address(this));

        (string memory name, uint sku, uint price, uint state, address seller, address buyer) = sp.fetchItem(0);

        Assert.equal(seller, msg.sender, "Seller is incorrect ");
        Assert.equal(name, "Test Item", "Name is incorrect");
        Assert.equal(sku, 0, "Sku is incorrect");
        Assert.equal(price, 100, "Price is incorrect");
        Assert.equal(state, 1, "State is incorrect");
        Assert.equal(buyer, address(this), "Buyer is incorrect");
    }

    //i test for failure if user does not send enough funds
    function testNotEnoughFunds() public {
        (,,uint price,,,) = sp.fetchItem(0);
        
        //Check the price
        Assert.equal(price, 100, "The price should be 100 wei");

        (bool success, ) = address(sp).call{value: 50}(abi.encodeWithSignature("buyItem(uint256,address)", 0, msg.sender));

        Assert.isFalse(success, "It should be revert due to the item is not for sale");
    }

    //s test for purchasing an item that is not for Sale
    function testNotForSale() public {
        sp.buyItem{value: 100}(0, msg.sender);

        (,,,uint state,,) = sp.fetchItem(0);

        //Check the State
        Assert.equal(state, 1, "The state shoul be 1 (Sold)");

        (bool success, ) = address(sp).call{value: 100}(abi.encodeWithSignature("buyItem(uint256,address)", 0, address(this)));

        Assert.isFalse(success, "It should be revert due to the item is not for sale");
    }

    //t shipItem
    function testShipItem() public {
        sp.addItem("Test Item", 100, address(this));
        
        sp.buyItem{value: 100}(1, msg.sender);
        
        (,,, uint state,, address buyer) = sp.fetchItem(1);

        Assert.equal(state, 1, "Not sold");
        Assert.equal(buyer, msg.sender, "Not the same, buyer - Sender");

        (bool success, ) = address(sp).call(abi.encodeWithSignature("shipItem(uint256)", 1));

        Assert.isTrue(success, "If it fail the item was not shipped");

    }
    
    //i test for calls that are made by not the seller
    function testShipByNotSeller() public {
        sp.buyItem{value: 100}(0, address(this));
        
        (,,, uint state, address seller, address buyer) = sp.fetchItem(0);

        Assert.equal(state, 1, "Not sold");
        Assert.equal(seller, msg.sender, "The seller is not the sender");
        Assert.equal(buyer, address(this), "Not the same, buyer - test");

        (bool success, ) = address(sp).call(abi.encodeWithSignature("shipItem(uint256)", 0));

        Assert.isFalse(success, "It should be revert due to the caller is not the seller");
    }

    //a test for trying to ship an item that is not marked Sold
    function testShipNotForSale() public {

        sp.addItem("Test Item", 100, address(this));
        
        (,,,uint state,,) = sp.fetchItem(1);

        Assert.equal(state, 0, "Not for sale");

        (bool success, ) = address(sp).call(abi.encodeWithSignature("shipItem(uint256)", 1));

        Assert.isFalse(success, "It should be revert due to the item is not marked Sold");
    }

    //n receiveItem
    function testReceiveItem() public {
        sp.addItem("Test Item", 100, address(this));
        
        sp.buyItem{value: 100}(1, address(this));
        
        (,,, uint state,, address buyer) = sp.fetchItem(1);

        Assert.equal(state, 1, "Not sold");
        Assert.equal(buyer, address(this), "Not the same, buyer - Test");

        sp.shipItem(1);

        (bool success, ) = address(sp).call(abi.encodeWithSignature("receiveItem(uint256)", 1));

        Assert.isTrue(success, "If it fail the item was not received");

    }

    //j test calling the function from an address that is not the buyer
    function testReceiveNotTheBuyer() public {
        sp.addItem("Test Item", 100, address(this));

        sp.buyItem{value: 100}(1, msg.sender);
        
        sp.shipItem(1);
        
        (bool success, ) = address(sp).call(abi.encodeWithSignature("receiveItem(uint256)", 1));

        Assert.isFalse(success, "It should be revert due to the caller is not the Buyer");
    }

    //a test calling the function on an item not marked Shipped
    function testReceiveNotShipped() public {
        sp.addItem("Test item", 100, address(this));

        sp.buyItem{value: 100}(1, address(this));

        (bool success, ) = address(sp).call(abi.encodeWithSignature("receiveItem(uint256)", 1));

        Assert.isFalse(success, "It should be revert due to the item is not Shipped");
    }

    //v fallback
    fallback() external payable {}
    receive() external payable {}
}