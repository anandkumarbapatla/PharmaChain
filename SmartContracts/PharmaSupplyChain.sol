// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24;

// inherited contracts
import './Ownable.sol';
import './ManufacturerRole.sol';
import './DistributorRole.sol';
import './RetailerRole.sol';
import './ConsumerRole.sol';
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

// Define a contract 'Pharma Supply Chain'
contract PharmaSupplyChain is Ownable,ManufacturerRole,DistributorRole,RetailerRole,ConsumerRole,ChainlinkClient{
    using Chainlink for Chainlink.Request;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    address private oracleIdInt;
    bytes32 private jobIdInt;
    uint256 private feeInt;
    uint256 public temperature;
    uint256 public humidity;
    uint256 public latitude;
    int public longitude;
    uint256 public lotNumber;
  // Define 'owner'
  address owner;
  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;
  string sku;
   // Define a public mapping 'items' that maps the UPC to an Item.
   mapping (uint => Item) items ;
  // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash,
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (uint => Txblocks) itemsHistory;

  // Define enum 'State' with the following values:
  enum State
  {
    ProducedByManufacturer,                  // 0
    UpdateInventoryByManufacturer,          // 1
    PurchasedByDistributor,                 // 2
    ShippedByManufacturer,                  // 3
    ReceivedByDistributor,                  // 4
    ProcessedByDistributor,                 // 5
    PackagedByDistributor,                   // 6
    ForSaleByDistributor,                   // 7
    PurchasedByRetailer,                    // 8
    ShippedByDistributor,                   // 9
    ReceivedByRetailer,                     // 10
    ForSaleByRetailer,                      // 11
    PurchasedByConsumer                     // 12
    }

    State constant defaultState = State.ProducedByManufacturer;

    // Define a struct 'Item' with the following fields:
  struct Item {
      address ownerID;
      uint lotNumber; //Manufactured lot number assigned by Manufacturer
      string sku; //Manufacturer Provided Stock Keeping Unit ID
      uint256 latitude; //Latitude position of the drug
      int longitude; //Longitude position of the drug
      string drugname; //Drug Name
      uint humidity; //Relative humidity around the shipment
      uint temperature; //Ambient Temperature around shipment
      uint upc;
      State   itemState;              // Product State as represented in the enum above
      address originManufacturerID;
      address distributorID;          // Metamask-Ethereum address of the Distributor
    address retailerID;             // Metamask-Ethereum address of the Retailer
    address consumerID;             // Metamask-Ethereum address of the Consumer // ADDED payable
  }

  // Block number stuct
  struct Txblocks {
    uint MTD; // blockManufacturerToDistributor
    uint DTR; // blockDistributorToRetailer
    uint RTC; // blockRetailerToConsumer
  }

  event ProducedByManufacturer(uint upc);               //1
  event UpdateInventoryByManufacturer(uint upc);        //2
  event PurchasedByDistributor(uint upc);               //3
  event ShippedByManufacturer(uint upc);                //4
  event ReceivedByDistributor(uint upc);                //5
  event ProcessedByDistributor(uint upc);               //6
  event PackagedByDistributor(uint upc);                //7
  event ForSaleByDistributor(uint upc);                 //8
  event PurchasedByRetailer(uint upc);                  //9
  event ShippedByDistributor(uint upc);                 //10
  event ReceivedByRetailer(uint upc);                   //11
  event ForSaleByRetailer(uint upc);                    //12
  event PurchasedByConsumer(uint upc);                  //13

    // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address);
    _;
  }

    //Item State Modifiers
  modifier producedByManufacturer(uint _upc) {
    require(items[_upc].itemState == State.ProducedByManufacturer);
    _;
  }

  modifier updateInventoryByManufacturer(uint _upc) {
    require(items[_upc].itemState == State.UpdateInventoryByManufacturer);
    _;
  }

  modifier purchasedByDistributor(uint _upc) {
    require(items[_upc].itemState == State.PurchasedByDistributor);
    _;
  }

  modifier shippedByManufacturer(uint _upc) {
    require(items[_upc].itemState == State.ShippedByManufacturer);
    _;
  }

  modifier receivedByDistributor(uint _upc) {
    require(items[_upc].itemState == State.ReceivedByDistributor);
    _;
  }

  modifier processByDistributor(uint _upc) {
    require(items[_upc].itemState == State.ProcessedByDistributor);
    _;
  }

  modifier packagedByDistributor(uint _upc) {
    require(items[_upc].itemState == State.PackagedByDistributor);
    _;
  }

  modifier forSaleByDistributor(uint _upc) {
    require(items[_upc].itemState == State.ForSaleByDistributor);
    _;
  }


  modifier shippedByDistributor(uint _upc) {
    require(items[_upc].itemState == State.ShippedByDistributor);
    _;
  }

  modifier purchasedByRetailer(uint _upc) {
    require(items[_upc].itemState == State.PurchasedByRetailer);
    _;
  }

  modifier receivedByRetailer(uint _upc) {
    require(items[_upc].itemState == State.ReceivedByRetailer);
    _;
  }

  modifier forSaleByRetailer(uint _upc) {
    require(items[_upc].itemState == State.ForSaleByRetailer);
    _;
  }

  modifier purchasedByConsumer(uint _upc) {
    require(items[_upc].itemState == State.PurchasedByConsumer);
    _;
  }

  constructor() {
    setPublicChainlinkToken();
    owner = msg.sender;
    oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
    jobId = "d5270d1c311941d0b08bead21fea7747";
    fee = 0.1 * 10 ** 18; // (Varies by network and job)
    oracleIdInt = 0x9C0383DE842A3A0f403b0021F6F85756524d5599;
    jobIdInt = "ba1d5d5070a247eaa7070f838a42bb03";
    feeInt = 0.1 * 10 ** 18; // (Varies by network and job)
  }

  /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestTemperatureData(string memory _sku) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        string memory url = "https://ej7guxgo78.execute-api.us-east-2.amazonaws.com/items/";
        string memory completeUrl = string(abi.encodePacked(url, _sku));
        request.add("get", completeUrl);
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "Items.0.temperature");
        
             
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    

    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _temperature) public recordChainlinkFulfillment(_requestId)
    {
        temperature = _temperature;
    }

    function requestHumidityData(string memory _sku) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill2.selector);
        
        // Set the URL to perform the GET request on
        // Set the URL to perform the GET request on
        string memory url = "https://ej7guxgo78.execute-api.us-east-2.amazonaws.com/items/";
        string memory completeUrl = string(abi.encodePacked(url, _sku));
        request.add("get", completeUrl);
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "Items.0.humidity");
        
             
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    

    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill2(bytes32 _requestId, uint256 _humidity) public recordChainlinkFulfillment(_requestId)
    {
        humidity = _humidity;
    }

    function requestLatitude(string memory _sku) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill3.selector);
        // Set the URL to perform the GET request on
        // Set the URL to perform the GET request on
        string memory url = "https://ej7guxgo78.execute-api.us-east-2.amazonaws.com/items/";
        string memory completeUrl = string(abi.encodePacked(url, _sku));
        request.add("get", completeUrl);
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "Items.0.latitude");
        int timesAmount = 10**5;
        request.addInt("times", timesAmount);
        
             
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    

    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill3(bytes32 _requestId, uint _latitude) public recordChainlinkFulfillment(_requestId)
    {
        latitude = _latitude;
    }

function requestLongitude(string memory _sku) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobIdInt, address(this), this.fulfill4.selector);
        
        // Set the URL to perform the GET request on
        // Set the URL to perform the GET request on
        string memory url = "https://ej7guxgo78.execute-api.us-east-2.amazonaws.com/items/";
        string memory completeUrl = string(abi.encodePacked(url, _sku));
        request.add("get", completeUrl);
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "Items.0.longitude");
        int timesAmount = 10**5;
        request.addInt("times", timesAmount);
        
             
        // Sends the request
        return sendChainlinkRequestTo(oracleIdInt, request, fee);
    }

      /**
     * Receive the response in the form of uint256
     */ 
    function fulfill4(bytes32 _requestId, int _longitude) public recordChainlinkFulfillment(_requestId)
    {
        longitude = _longitude;
    }
    
        function requestLotNumber(string memory _sku) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill5.selector);
        
        // Set the URL to perform the GET request on
        string memory url = "https://ej7guxgo78.execute-api.us-east-2.amazonaws.com/items/";
        string memory completeUrl = string(abi.encodePacked(url, _sku));
        request.add("get", completeUrl);
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "Items.0.lot");
        
             
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    

    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill5(bytes32 _requestId, uint256 _lotNumber) public recordChainlinkFulfillment(_requestId)
    {
        lotNumber = _lotNumber;
    }


  function produceItemByManufacturer(string memory _sku, string memory _drugName, uint _upc) public
    onlyManufacturer() // check address belongs to ManufacturerRole
    {
        
        Item memory newProductLot; // Create a new struct Item in memory
        newProductLot.ownerID = msg.sender;
        newProductLot.sku = _sku;
        newProductLot.drugname = _drugName;
        newProductLot.originManufacturerID = msg.sender;
        uint placeholder; // Block number place holder
        Txblocks memory txBlock; // create new txBlock struct
        txBlock.MTD = placeholder; // assign placeholder values
        txBlock.DTR = placeholder;
        txBlock.RTC = placeholder;
        requestTemperatureData(_sku);
        requestHumidityData(_sku);
        requestLatitude(_sku);
        requestLongitude(_sku);
        requestLotNumber(_sku);
        newProductLot.temperature = temperature;
        newProductLot.humidity = humidity;
        newProductLot.latitude = latitude;
        newProductLot.longitude = longitude;
        newProductLot.lotNumber = lotNumber;
        items[_upc] = newProductLot; // Add newProduce to items struct by upc
         itemsHistory[_upc] = txBlock; // add txBlock to itemsHistory mapping by upc
         emit ProducedByManufacturer(_upc);
    }
  
  /*
    2nd step in supplychain
    Allows Manufacturer to sell produced drug
  */
  function sellItemByManufacturer(uint _upc) public
    onlyManufacturer() // check msg.sender belongs to farmerRole
    producedByManufacturer(_upc) // check items state has been produced
    verifyCaller(items[_upc].ownerID) // check msg.sender is owner
    {
      items[_upc].itemState = State.UpdateInventoryByManufacturer;
      requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      requestLotNumber(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
      items[_upc].lotNumber = lotNumber;
      emit UpdateInventoryByManufacturer(_upc);
    }
  
  /*
3rd step in supplychain
Allows distributor to purchase drug from manufacturer
*/
  function purchaseItemByDistributor(uint _upc) public
    onlyDistributor() // check msg.sender belongs to distributorRole
    updateInventoryByManufacturer(_upc) // check items state is for ForSaleByFarmer
    {
    items[_upc].ownerID = msg.sender; // update owner
    items[_upc].distributorID = msg.sender; // update distributor
    items[_upc].itemState = State.PurchasedByDistributor; // update state
    itemsHistory[_upc].MTD = block.number; // add block number
    requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
    emit PurchasedByDistributor(_upc);
  }
  /*
  4th step in supplychain
  Allows farmer to ship cheese purchased by distributor
  */
  function shippedItemByManufacturer(uint _upc) public 
    onlyManufacturer() // check msg.sender belongs to FarmerRole
    purchasedByDistributor(_upc)
    verifyCaller(items[_upc].originManufacturerID) // check msg.sender is originFarmID
    {
    items[_upc].itemState = State.ShippedByManufacturer; // update state
    requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
    emit ShippedByManufacturer(_upc);
  }

  /*
  5th step in supplychain
  Allows distributor to receive cheese
  */
  function receivedItemByDistributor(uint _upc) public
    onlyDistributor() // check msg.sender belongs to DistributorRole
    shippedByManufacturer(_upc)
    verifyCaller(items[_upc].ownerID) // check msg.sender is owner
    {
    items[_upc].itemState = State.ReceivedByDistributor; // update state
    requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
    emit ReceivedByDistributor(_upc);
  }

  /*
  6th step in supplychain
  Allows distributor to process cheese
  */
  function processedItemByDistributor(uint _upc) public
    onlyDistributor() // check msg.sender belongs to DistributorRole
    receivedByDistributor(_upc)
    verifyCaller(items[_upc].ownerID) // check msg.sender is owner
    {
    items[_upc].itemState = State.ProcessedByDistributor; // update state
    requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
    emit ProcessedByDistributor(_upc);
  }

    /*
  7th step in supplychain
  Allows distributor to package cheese
  */
  function packageItemByDistributor(uint _upc) public
    onlyDistributor() // check msg.sender belongs to DistributorRole
    processByDistributor(_upc)
    verifyCaller(items[_upc].ownerID) // check msg.sender is owner
    {
    items[_upc].itemState = State.PackagedByDistributor;
    requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
    emit PackagedByDistributor(_upc);
  }

 /*
  8th step in supplychain
  Allows distributor to sell cheese
  */
  function sellItemByDistributor(uint _upc) public
    onlyDistributor() // check msg.sender belongs to DistributorRole
    packagedByDistributor(_upc)
    verifyCaller(items[_upc].ownerID) // check msg.sender is owner
    {
        items[_upc].itemState = State.ForSaleByDistributor;
       requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
        emit ForSaleByDistributor(upc);
  }

  /*
  9th step in supplychain
  Allows retailer to purchase cheese
  */
  function purchaseItemByRetailer(uint _upc) public 
    onlyRetailer() // check msg.sender belongs to RetailerRole
    forSaleByDistributor(_upc)
    {
    items[_upc].ownerID = msg.sender;
    items[_upc].retailerID = msg.sender;
    items[_upc].itemState = State.PurchasedByRetailer;
    itemsHistory[_upc].DTR = block.number;
    requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
    emit PurchasedByRetailer(_upc);
  }

  /*
  10th step in supplychain
  Allows Distributor to
  */
  function shippedItemByDistributor(uint _upc) public
    onlyDistributor() // check msg.sender belongs to DistributorRole
    purchasedByRetailer(_upc)
    verifyCaller(items[_upc].distributorID) // check msg.sender is distributorID
    {
      items[_upc].itemState = State.ShippedByDistributor;
      requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
      emit ShippedByDistributor(_upc);
  }

  /*
  11th step in supplychain
  */
  function receivedItemByRetailer(uint _upc) public
    onlyRetailer() // check msg.sender belongs to RetailerRole
    shippedByDistributor(_upc)
    verifyCaller(items[_upc].ownerID) // check msg.sender is ownerID
    {
      items[_upc].itemState = State.ReceivedByRetailer;
      requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
      emit ReceivedByRetailer(_upc);
  }

  /*
  12th step in supplychain
  */
  function sellItemByRetailer(uint _upc) public
    onlyRetailer()  // check msg.sender belongs to RetailerRole
    receivedByRetailer(_upc)
    verifyCaller(items[_upc].ownerID) // check msg.sender is ownerID
    {
      items[_upc].itemState = State.ForSaleByRetailer;
      requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
      emit ForSaleByRetailer(_upc);
  }

 /*
  13th step in supplychain
  */
  function purchaseItemByConsumer(uint _upc) public
    onlyConsumer()  // check msg.sender belongs to ConsumerRole
    forSaleByRetailer(_upc)
    {
      items[_upc].consumerID = msg.sender;
      items[_upc].ownerID = msg.sender;
      items[_upc].consumerID = msg.sender;
      items[_upc].itemState = State.PurchasedByConsumer;
      itemsHistory[_upc].RTC = block.number;
      requestTemperatureData(items[_upc].sku);
      requestHumidityData(items[_upc].sku);
      requestLatitude(items[_upc].sku);
      requestLongitude(items[_upc].sku);
      items[_upc].latitude = latitude;
      items[_upc].longitude = longitude;
      items[_upc].temperature = temperature;
      items[_upc].humidity = humidity;
    emit PurchasedByConsumer(_upc);
  }

  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns
    (
    uint  lot,
    string  memory SKU,
    address ownerID,
    address originManufacturerID,
    uint  latitudeValue,
    int  longitudeValue,
    string memory drugname,
    uint temp,
    uint hum,
    State itemState
    )
    {
    // Assign values to the 8 parameters
    Item memory item = items[_upc];

    return
    (
      item.lotNumber,
      item.sku,
      item.ownerID,
      item.originManufacturerID,
      item.latitude,
      item.longitude,
      item.drugname,
      item.temperature,
      item.humidity,
      item.itemState
    );
  }

  // Define a function 'fetchItemHistory' that fetaches the data
  function fetchitemHistory(uint _upc) public view returns
    (
      uint blockManufactrerToDistributor,
      uint blockDistributorToRetailer,
      uint blockRetailerToConsumer
    )
    {
      // Assign value to the parameters
      Txblocks memory txblock = itemsHistory[_upc];
      return
      (
        txblock.MTD,
        txblock.DTR,
        txblock.RTC
      );

    }

}