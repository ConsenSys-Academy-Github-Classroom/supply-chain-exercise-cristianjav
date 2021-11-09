// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {

  address public owner;

  uint public skuCount;

  mapping(uint => Item) public items;

  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  /* 
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint sku);

  // <LogSold event: sku arg>
  event LogSold(uint sku);

  // <LogShipped event: sku arg>
  event LogShipped(uint sku);

  // <LogReceived event: sku arg>
  event LogReceived(uint sku);


  /* 
   * Modifiers
   */

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract

  modifier isOwner (address _address) {
    require(owner == msg.sender, "Sender is not the owner");
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address, "Sender is not the seller or buyer");
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price, "Payment is not enough");
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    if(amountToRefund > 0) {
      items[_sku].buyer.transfer(amountToRefund);
    }
  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

  
  modifier forSale(uint _sku) {
    require(items[_sku].state == State.ForSale, "This item is not for sale");
    require(items[_sku].seller != address(0), "This item is not for sale");
    _;
  }
  
  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold, "This article was not sold");
    _;
  } 
  
  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped, "This article was not shipped");
    _;
  }
  
  modifier received(uint _sku) {
    require(items[_sku].state == State.Received, "This article was not received");
    _;
  }

  constructor() {
    // 1. Set the owner to the transaction sender
    // 2. Initialize the sku count to 0. Question, is this necessary?
    // The default value of a uint type variable is 0
    owner = msg.sender;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array
    // 2. Increment the skuCount by one
    // 3. Emit the appropriate event
    // 4. return true
    require(bytes(_name).length != 0, "No name was received");
    require(_price > 0, "No price was received");

    Item memory newItem = Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: payable(msg.sender),
      buyer: payable(address(0))
    });

    items[skuCount] = newItem;
    
    skuCount++;
    
    emit LogForSale(skuCount - 1);

    return true;
  }

  // Implement this buyItem function. 
  // 1. it should be payable in order to receive refunds
  // 2. this should transfer money to the seller, 
  // 3. set the buyer as the person who called this transaction, 
  // 4. set the state to Sold. 
  // 5. this function should use 3 modifiers to check 
  //    - if the item is for sale, 
  //    - if the buyer paid enough, 
  //    - check the value after the function is called to make 
  //      sure the buyer is refunded any excess ether sent. 
  // 6. call the event associated with this function!
  function buyItem(uint _sku) public payable forSale(_sku) paidEnough(items[_sku].price) checkValue(_sku) {
    //require(_buyer != address(0), "Buy Item: Zero address");

    Item memory item = items[_sku];
    
    item.seller.transfer(item.price);
    
    item.buyer = payable(msg.sender);

    item.state = State.Sold;

    items[_sku] = item;

    emit LogSold(_sku);
  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint _sku) public sold(_sku) verifyCaller(items[_sku].seller) {
    items[_sku].state = State.Shipped;
    emit LogShipped(_sku);
  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint _sku) public shipped(_sku) verifyCaller(items[_sku].buyer) {
    items[_sku].state = State.Received;
    emit LogReceived(_sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view 
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
   }
}
