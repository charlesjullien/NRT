// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract NRTPresale is Ownable {

    IERC721 public GMX; // address == 0x17f4BAa9D35Ee54fFbCb2608e20786473c7aa49f // (check it tho)
    IERC20 public StableCoin;
    IERC20 public NRT;

    mapping(address => bool) public isWhitelisted;
    mapping(address => uint) totalInvestedUSD;
    mapping(address => uint) totalInvestedNRT;
    mapping(address => uint) amountLeftToWithdraw;
    mapping(address => uint) amountWithdrawn;
    // mapping(address => uint) secondsForOneNRT;
    mapping(address => uint) lastWithdrawTimestamp;


    uint256 public PRIVATE_SALE_VESTING_START_DATE;
    uint256 public PRIVATE_SALE_VESTING_END_DATE;
    uint256 public PRIVATE_SALE_VESTING_DURATION;
    // seconds to 100% full unlock : 17515872

    uint totalNRTInvested;
    uint totalUSDInvested;

    address teamWallet;

    bool presaleClosed;
    bool vestingClosed;


    // constructor (address _GMXContract, address _USDCContract, address _teamWallet) {
    //     GMX = IERC721(_GMXContract);
    //     StableCoin = IERC20(_USDCContract);
    //     teamWallet = _teamWallet;

    //     // lastWithdrawTimestamp[msg.sender] = PRIVATE_SALE_VESTING_END_DATE; // delete de là
    //     //totalInvestedNRT[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 317377; 
    //     //amountLeftToWithdraw[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 317377;
    //     // secondsForOneNRT[msg.sender] = (26274240 / totalInvestedNRT[msg.sender]); //... à là
    // }

    function forTesting (uint _amount) external {
        totalInvestedNRT[msg.sender] = _amount;
        amountLeftToWithdraw[msg.sender] = totalInvestedNRT[msg.sender];
    }

    function changeStableCoinInterface (address _newStableCoinContract) external onlyOwner {
        StableCoin = IERC20(_newStableCoinContract);
    }

    function whitelistManyUsers(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isWhitelisted[_users[i]] = true;
        }
    }

    function closePresale (address NRTContract) external onlyOwner {
        presaleClosed = true;
        PRIVATE_SALE_VESTING_START_DATE = block.timestamp;
        PRIVATE_SALE_VESTING_END_DATE = block.timestamp + 86471; //+ 26274240; <==== REMETTRE CA // 26274240 == (nb seconds in a day) x 304.1 days (10 months).
        PRIVATE_SALE_VESTING_DURATION = PRIVATE_SALE_VESTING_END_DATE - PRIVATE_SALE_VESTING_START_DATE;
        NRT = IERC20(NRTContract);
    }

    function markVestingAsClosed () external onlyOwner {
        vestingClosed = true;
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
        // secondsForOneNRT[msg.sender] = (17515872 / totalInvestedNRT[msg.sender]);
        totalNRTInvested += (_USDamount * 20) / 1000000;
        totalUSDInvested += _USDamount;
    }


    function releasePrivatesaleVesting () external { //add reentrancyguards ?
        require (amountLeftToWithdraw[msg.sender] > 0, "You are not part of the private sale investors.");
        require (block.timestamp > PRIVATE_SALE_VESTING_START_DATE, "End date has not been reached yet for privates sale investors.");
        require (getWidthdrawableAmount() > 0, "You cannot withdraw for now.");
        require (NRT.approve(address(this), getWidthdrawableAmount()), "Approval failed.");
        require (NRT.transferFrom(address(this), msg.sender, getWidthdrawableAmount()), "Transfer Failed.");
        lastWithdrawTimestamp[msg.sender] = block.timestamp;
    }

    function withdrawLeftovers () external { //add reentrancyguards  or a mapping hasWithdrawnLeftovers ?
        require (amountLeftToWithdraw[msg.sender] > 0, "You are not part of the private sale investors.");
        require (block.timestamp > PRIVATE_SALE_VESTING_END_DATE, "End Date has not been reached yet.");
        require (vestingClosed == true, "Vesting has not been closed yet");
        require (NRT.approve(address(this), getWidthdrawableAmount()), "Approval failed.");
        require (NRT.transferFrom(address(this), msg.sender, amountLeftToWithdraw[msg.sender]), "Transfer Failed.");
        amountLeftToWithdraw[msg.sender] = 0;
    }

    function getTimeLeftForPrivateSaleEndDate () public view returns (uint) {
        return (PRIVATE_SALE_VESTING_END_DATE - block.timestamp);
    }

    function getWidthdrawableAmount () public view returns (uint) {
        require(block.timestamp > PRIVATE_SALE_VESTING_START_DATE, "End date has not been reached yet for privates sale investors.");
        uint amount;
        if (lastWithdrawTimestamp[msg.sender] == 0)
            amount = (block.timestamp - PRIVATE_SALE_VESTING_START_DATE) / getSecondsForUnlockingOneNRT();
        else
            amount = (block.timestamp - lastWithdrawTimestamp[msg.sender]) / getSecondsForUnlockingOneNRT();
        return (amount);
    }

    function getSecondsForUnlockingOneNRT () public view returns (uint) {
        return (PRIVATE_SALE_VESTING_DURATION / totalInvestedNRT[msg.sender]);
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