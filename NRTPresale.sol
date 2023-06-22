// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract NRTPresale is Ownable {

    IERC721 public GMX; // address == 0x17f4BAa9D35Ee54fFbCb2608e20786473c7aa49f // (check it tho)
    IERC20 public StableCoin;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) totalInvestedUSD;
    mapping(address => uint) totalInvestedNRT;
    mapping(address => uint) amountLeftToWithdraw;
    mapping(address => uint) amountWithdrawn;
    mapping(address => uint) secondsForOneNRT;
    mapping(address => uint) lastWithdrawTimestamp;

    mapping(address => uint) public totalPrivateSaleVault;
    mapping(address => uint) public currentPrivateSaleVault;

    uint256 public PRIVATE_SALE_VESTING_END_DATE;
    uint256 public PRIVATE_SALE_VESTING_MONTHLY_UNLOCK_RATE = 15;
    // seconds to 100% full unlock : 17515872

    uint totalNRTInvested;
    uint totalUSDInvested;

    address teamWallet;

    bool presaleClosed;


    constructor (address _GMXContract, address _USDCContract, address _teamWallet) {
        GMX = IERC721(_GMXContract);
        StableCoin = IERC20(_USDCContract);
        teamWallet = _teamWallet;
        PRIVATE_SALE_VESTING_END_DATE = block.timestamp + 3; //+ 26274240; <==== REMETTRE CA // 26274240 == (nb seconds in a day) x 304.1 days (10 months).

        // lastWithdrawTimestamp[msg.sender] = PRIVATE_SALE_VESTING_END_DATE; // delete de là
        //totalInvestedNRT[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 317377; 
        //amountLeftToWithdraw[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 317377;
        // secondsForOneNRT[msg.sender] = (26274240 / totalInvestedNRT[msg.sender]); //... à là
    }


    function changeStableCoinInterface (address _newStableCoinContract) external onlyOwner {
        StableCoin = IERC20(_newStableCoinContract);
    }

    function whitelistManyUsers(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = true;
        }
    }

    function closePresale () external onlyOwner {
        presaleClosed = true;
    }

    function allowedInvestingamount () public view returns (uint) {
        uint nbrOfGMXAssets;
        uint total;
        nbrOfGMXAssets = GMX.balanceOf(msg.sender);
        if (isWhitelisted[msg.sender])
            total = (nbrOfGMXAssets * 500) + 2000;
        else
            total = (nbrOfGMXAssets * 500);
        return (total * 10**6 - totalInvestedUSD[msg.sender]);
    }

    function allowStableCoinContractToSpend1 (uint _USDamount) external {
        _USDamount = _USDamount * 10**6;
        require (isWhitelisted[msg.sender] || GMX.balanceOf(msg.sender) > 0, "You either are not whitelisted or do not possess any GMX NFT.");
        require ((totalInvestedUSD[msg.sender] + _USDamount) < allowedInvestingamount(), "You cannot invest that much.");
        require (_USDamount > 0, "amount must be greater than 0");
        require (StableCoin.approve(msg.sender, _USDamount), "Stable coin contract failed to make an allowance for you.");
    }

    function allowStableCoinContractToSpend2 (uint _USDamount) external {
        _USDamount = _USDamount * 10**6;
        require (isWhitelisted[msg.sender] || GMX.balanceOf(msg.sender) > 0, "You either are not whitelisted or do not possess any GMX NFT.");
        require ((totalInvestedUSD[msg.sender] + _USDamount) < allowedInvestingamount(), "You cannot invest that much.");
        require (_USDamount > 0, "amount must be greater than 0");
        require (StableCoin.approve(address(this), _USDamount), "Stable coin contract failed to make an allowance for you.");
    }

    function invest (uint _USDamount) external {
        _USDamount = _USDamount * 10**6;
        require (isWhitelisted[msg.sender] || GMX.balanceOf(msg.sender) > 0, "You either are not whitelisted or do not possess any GMX NFT.");
        require ((totalInvestedUSD[msg.sender] + _USDamount) < allowedInvestingamount(), "You cannot invest that much.");
        require (_USDamount > 0, "amount must be greater than 0");
        require (StableCoin.balanceOf(msg.sender) >= _USDamount, "Insufficient stableCoin balance.");
        require (StableCoin.transferFrom(msg.sender, teamWallet, _USDamount));
        require (presaleClosed == false, "Presale phase is now over");

        totalInvestedUSD[msg.sender] += _USDamount;
        totalInvestedNRT[msg.sender] += (_USDamount * 20) / 1000000;
        amountLeftToWithdraw[msg.sender] = totalInvestedNRT[msg.sender];
        secondsForOneNRT[msg.sender] = (17515872 / totalInvestedNRT[msg.sender]);
        totalNRTInvested += (_USDamount * 20) / 1000000;
        totalUSDInvested += _USDamount;
    }


    function releasePrivatesaleVesting () external {
        require(totalPrivateSaleVault[msg.sender] > 0, "You are not part of the private sale investors.");
        require(block.timestamp > PRIVATE_SALE_VESTING_END_DATE, "End date has not been reached yet for privates sale investors.");
        uint i = 0;
        i = 1;
    }

    function getTimeLeftForPrivateSaleVestingRelease () public view returns (uint) {
        return (PRIVATE_SALE_VESTING_END_DATE - block.timestamp);
    }

    function getWidthdrawableAmount () public view returns (uint) {
        require(block.timestamp > PRIVATE_SALE_VESTING_END_DATE, "End date has not been reached yet for privates sale investors.");
        uint _amount = (block.timestamp - lastWithdrawTimestamp[msg.sender]) / secondsForOneNRT[msg.sender];
        return (_amount);
    }

    function getSecondsForUnlockingAnNRT () public view returns (uint) {
        return (secondsForOneNRT[msg.sender]);
    }

    function getAllTotalUSDInvested () external onlyOwner view returns (uint) {
        return (totalUSDInvested);
    }

    function getAllTotalNRTInvested () external onlyOwner view returns (uint) {
        return (totalNRTInvested);
    }

    function getTotalUSDInvested () external view returns (uint) {
        return (totalInvestedUSD[msg.sender]);
    }

    function getTotalNRTInvested () external view returns (uint) {
        return (totalInvestedNRT[msg.sender]);
    }
}