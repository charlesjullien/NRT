// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//"0xd374410e9bb22f3771ffbd0b40a07c0cf44a04fa", "0xd374410e9bb22f3771ffbd0b40a07c0cf44a04fb", "0xd374410e9bb22f3771ffbd0b40a07c0cf44a04fc"

contract NRTPresale is Ownable {

    IERC721 public GMX; // adress == 0x17f4BAa9D35Ee54fFbCb2608e20786473c7aa49f // (check it tho)
    IERC20 public StableCoin;

    uint256 public PRIVATE_SALE_VESTING_END_DATE;
    uint256 public PRIVATE_SALE_VESTING_MONTHLY_UNLOCK_RATE = 15;
    // seconds to 100% full unlock : 17515872

    uint totalNRTInvested;

    mapping(address => uint) public totalPrivateSaleVault;
    mapping(address => uint) public currentPrivateSaleVault;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) totalInvestedUSD;
    mapping(address => uint) totalInvestedNRT;
    mapping(address => uint) amountLeftToWithdraw;
    mapping(address => uint) amountWithdrawn;
    mapping(address => uint) secondsForOneNRT;
    mapping(address => uint) lastWithdrawTimestamp;


    address teamWallet;

    constructor (address GMXContract, address stableCoinContract, address _teamWallet) {
        GMX = IERC721(GMXContract);
        StableCoin = IERC20(stableCoinContract);
        teamWallet = _teamWallet;
        PRIVATE_SALE_VESTING_END_DATE = block.timestamp + 3; //+ 26274240; <==== REMETTRE CA // 26274240 == (nb seconds in a day) x 304.1 days (10 months).
        lastWithdrawTimestamp[msg.sender] = PRIVATE_SALE_VESTING_END_DATE;
        totalInvestedNRT[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 267; // delete de là
        amountLeftToWithdraw[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 267;
        secondsForOneNRT[msg.sender] = (2669 / totalInvestedNRT[msg.sender]); //... à là
    }

    function changeStableCoinInterface (address newStableCoinContract) external onlyOwner {
        StableCoin = IERC20(newStableCoinContract);
    }

    function whitelistOneUser (address _user) external onlyOwner {
        isWhitelisted[_user] = true;
    }

    function whitelistManyUsers(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = true;
        }
    }


    function allowedInvestingamount () public view returns (uint) {
        uint nbrOfGMXAssets;
        uint total;
        nbrOfGMXAssets = GMX.balanceOf(msg.sender);
        if (isWhitelisted[msg.sender])
            total = (nbrOfGMXAssets * 500) + 2000;
        else
            total = (nbrOfGMXAssets * 500);
        return (total);
    }

    function invest (uint _amount) external {
        require (isWhitelisted[msg.sender] || GMX.balanceOf(msg.sender) > 0, "You either are not whitelisted or do not possess any GMX NFT.");
        require (totalInvestedUSD[msg.sender] + (_amount * 5 * 10**5) < allowedInvestingamount(), "You cannot invest that much.");
        
        uint256 stableCoinAmount = _amount * 5 * 10**5; // stableCoin decimals == 6
        require(StableCoin.balanceOf(msg.sender) >= stableCoinAmount, "Insufficient stableCoin balance.");
        require(StableCoin.transferFrom(msg.sender, teamWallet, stableCoinAmount), "Failed to transfer stableCoin.");

        totalInvestedUSD[msg.sender] += stableCoinAmount;
        totalInvestedNRT[msg.sender] += _amount;
        amountLeftToWithdraw[msg.sender] = totalInvestedNRT[msg.sender];
        secondsForOneNRT[msg.sender] = (17515872 / totalInvestedNRT[msg.sender]);
        totalNRTInvested += _amount;
    }

    function releasePrivatesaleVesting () external {
        require(totalPrivateSaleVault[msg.sender] > 0, "You are not part of the private sale investors.");
        require(block.timestamp > PRIVATE_SALE_VESTING_END_DATE, "End date has not been reached yet for privates sale investors.");
        
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

}