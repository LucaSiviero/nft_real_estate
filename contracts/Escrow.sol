//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address public nftAddress;
    address public lender;
    address public inspector;
    address payable public seller;

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this method");
        _;
    }

    //We make sure that the sender of the message is the buyer for the specific NFT
    modifier onlyBuyer(uint256 _nftID){
        require(msg.sender == buyer[_nftID], "Only the buyer can call this method");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }

    //NFT ID => listed yes/no
    mapping(uint256 => bool) public isListed;
    //NFT ID => cost in ETH
    mapping(uint256 => uint256) public purchasePrice;
    //NFT ID => Escrow Amount
    mapping(uint256 => uint256) public escrowAmount;
    //NFT ID => Buyer's address
    mapping(uint256 => address) public buyer;
    //NFT ID => Inspection process
    mapping(uint256 => bool) public inspectionPassed;
    //This is a nested mapping: NFT ID => mapping of the address who's approving. So this mapping has the key equal to the NFT ID and the value is a mapping
    mapping(uint256 => mapping(address => bool)) public approval;


    constructor(address _nftAddress, address payable _seller, address _inspector, address _lender) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }

    //public because list has to be accessed by everyone, but only the seller can call the method. It's payable because in this way we can pay ethers with this method
    function list(uint256 _nftID, uint256 _purchasePrice, uint256 _escrowAmount, address _buyer) public payable onlySeller {
        // This code transfers property from msg.sender (which is going to be the seller in this case) to the address of the contract (this), in reference to _nftID
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);
        
        //Set mappings values
        isListed[_nftID] = true;
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyer[_nftID] = _buyer;
    }

    //A function to deposit Earnest: the minimum amount of money payed by the buyer so that the escrow amount is payed and negotiation can start or minimum payment is satisfied
    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID) {
        require(msg.value >= escrowAmount[_nftID]);
    }

    function updateInspectionStatus(uint256 _nftID, bool _passed) public onlyInspector{
        inspectionPassed[_nftID] = _passed;
    }

    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    
    //Here we need to
    //Require inspection status
    //Require sale to be authorized
    //Require funds to be the correct amount
    //Transfer NFT to the buyer
    //Transfer funds to the seller
    function finalizeSale(uint256 _nftID) public {
        require(inspectionPassed[_nftID]);
        require(approval[_nftID][buyer[_nftID]]);
        require(approval[_nftID][seller]);
        require(approval[_nftID][lender]);
        require(address(this).balance >= purchasePrice[_nftID]);

        isListed[_nftID] = false;

        (bool success, ) = payable(seller).call{value: address(this).balance}("");
        require(success);
        
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }

    function cancelSale(uint256 _nftID) public {
        if(inspectionPassed[_nftID] == false) {
            payable(buyer[_nftID]).transfer(address(this).balance);
        }
        else {
            payable(seller).transfer(address(this).balance);
        }
    }
    
    receive() external payable { }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}