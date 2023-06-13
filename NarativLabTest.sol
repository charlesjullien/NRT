// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NarativLabTest is ERC1155, Ownable, ERC1155Supply, PaymentSplitter {

    uint256 public price = 0.01 ether;
    uint256 public maxSupply = 555;

    constructor(address[] memory _payTo, uint256[] memory _shares)
        ERC1155("https://bafybeieyuugjpmkcfxnqkxse4zbr2pywe4h4g2h64v5xwy4uq2xjqsv2b4.ipfs.nftstorage.link/")
        PaymentSplitter(_payTo, _shares)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(uint256 id, uint256 amount) public payable
    {
        require(msg.value == (price * amount), "Error : price is 0.01 ETH per id.");
        require(id == 0, "Only NFT with id 0 exists.");
        require(totalSupply(0) + amount <= maxSupply, "Max amount of mint reached.");
        require(balanceOf(msg.sender, 0) + amount <= 5, "You can possess a maximum of 5 items.");
        _mint(msg.sender, id, amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}