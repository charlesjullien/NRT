// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NarativTestToken is ERC20, Ownable {

    uint256 public MAX_SUPPLY = 50000000 * 10 ** decimals(); // 100 %
    uint256 public INITIAL_SUPPLY = 44100000 * 10 ** decimals();
    uint256 public AIRDROP_SUPPLY = 5600000 * 10 ** decimals(); // 11.2%
    uint256 public TEAM_SUPPLY = 7500000 * 10 ** decimals(); // 15%
    uint256 public REWARDS_SUPPLY = 5900000 * 10 ** decimals(); // 11.8%
    uint256 public PRIVATE_SALE_SUPPLY = 12000000 * 10 ** decimals(); // 24%
    uint256 public DEVELOPMENT_RESERVE_MARKETING_SUPPLY = 15000000 * 10 ** decimals(); // 31%
    uint256 public LIQUIDITY_SUPPLY = 3500000 * 10 ** decimals(); // 7%

    uint256 public TEAM_VESTING_END_DATE;
    uint256 public TEAM_VESTING_MONTHLY_UNLOCK_RATE = 10; 


    uint32 public MONTH = 2592000; // 30 (days) x 86400 (nb seconds in a day)
    uint256 public currentSupply; //use counters instead ?

    mapping(address => uint) public totalTeamVault;
    mapping(address => uint) public CurrentTeamVault;



    constructor() ERC20("NarativTestToken", "NTT") {
        _mint(msg.sender, 44100000 * 10 ** decimals());
        currentSupply = 44100000 * 10 ** decimals();
        TEAM_VESTING_END_DATE = block.timestamp + 42076800; // 42076800 == 86400 (nb seconds in a day) x 487 days (16 months).
       
        //add call to whitelistTeamMemberForVesting() function with matching addresses

    }

    function mint(address to, uint256 amount) public onlyOwner { // override erc20 SC mmint ?
        require((currentSupply + amount) < MAX_SUPPLY, "You cannot mint more than the maxiumum supply (50 M).");
        currentSupply += amount; 
        _mint(to, amount);
    }

    function whitelistUserForPrivateSaleVesting (address memory _investor, uint256 _amountInvestedInUSDC) external onlyOwner {
        // relire gitbook.
        require(_amountInvestedInUSDC <= 3000, "Maximum amount invested per user is 3000 USDC.");
        require(totalPrivateSaleVault[_investor] == 0, "You already added the investor share.");
        uint16 _NTTAmount = _amountInvestedInUSDC * 5 / 100;
        totalPrivateSaleVault[_investor] = _NTTAmount;
    }

    function whitelistTeamMemberForVesting (address memory _teamMember, uint256 _shareAmount) private onlyOwner { //check function type
        require(totalTeamVault[_teamMember] == 0, "You already added the team member share.");
        totalTeamVault[_teamMember] =  _shareAmount;
    }

    function releaseTeamVesting () external {
        require(totalTeamVault[msg.sender], "You are not part of the team.");
        require(block.timestamp > TEAM_VESTING_END_DATE, "End date has not been reached yet for team.");
        currentMonthPostTeamVesting = (block.timestamp - TEAM_VESTING_END_DATE) / MONTH;
    }




    function getTimeLeftForTeamVestingRelease () public view returns (uint) {
        return (TEAM_VESTING_END_DATE - block.timestamp);
    }

}