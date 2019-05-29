pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint PRICE_TICKET = 100 wei;
    address payable public owner;

    constructor()public {
        owner = msg.sender;
    }

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;
    uint public eventId;
    
    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        bool isOpen;
        mapping (address => uint) buyers;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) public events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() {
        require(owner == msg.sender,"Access Denied");
        _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string calldata _description, string calldata _webiste, uint _noTickets) onlyOwner external returns (uint){
        Event memory newEvent = Event(_description, _webiste, _noTickets, 0, true);
        events[eventId] = newEvent;
        emit LogEventAdded(_description, _webiste, _noTickets, eventId);
        eventId += 1;
        return eventId-1;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */     
    function readEvent(uint _eventId) 
        public view
        returns(string memory description, string memory website, uint ticketsAvailable, uint sales, bool isOpen) 
    {
        require(_eventId < eventId, "Invalid event Id");
        description = events[_eventId].description;
        website = events[_eventId].website;
        ticketsAvailable = events[_eventId].totalTickets - events[_eventId].sales;
        sales = events[_eventId].sales;
        isOpen = events[_eventId].isOpen;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventId, uint _noTickets) external payable{
        require(events[_eventId].isOpen == true, "Event has to be open");
        require(msg.value >= PRICE_TICKET * _noTickets, "no enough funds");
        require(_noTickets <= events[_eventId].totalTickets - events[_eventId].sales, "No enough tickets available");

        events[_eventId].buyers[msg.sender] += _noTickets;
        events[_eventId].sales += _noTickets;

        uint amountToRefund = msg.value - (PRICE_TICKET * _noTickets);
        msg.sender.transfer(amountToRefund);

        emit LogBuyTickets(msg.sender, _eventId, _noTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventId) external{
        require(events[_eventId].buyers[msg.sender] > 0, "User did not buy anything!");
        require(events[_eventId].isOpen == true, "Event has to be still open");

        uint amountOfTickets = events[_eventId].buyers[msg.sender];
        events[_eventId].buyers[msg.sender] = 0;
        events[_eventId].sales -= amountOfTickets;

        uint amountToRefund = amountOfTickets*PRICE_TICKET;
        msg.sender.transfer(amountToRefund);

        emit LogGetRefund(msg.sender, _eventId, amountOfTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventId) public view returns (uint){
        require(_eventId < eventId, "Invalid event Id");
        return events[_eventId].buyers[msg.sender];
    }


    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventId) public onlyOwner {
        events[_eventId].isOpen = false;
        uint balanceToTransfer = address(this).balance;
        owner.transfer(balanceToTransfer);

        emit LogEndSale(owner, balanceToTransfer);
    }
}