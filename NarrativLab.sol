// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NarativLab is ERC1155, ERC1155Supply, Ownable, PaymentSplitter {

    mapping(uint256 => string) private _tokenURI;
    mapping(uint256 => uint256) private _tokenPrice;
    mapping(uint256 => uint256) private _tokenSupply;
    // uint256 public price = 0.01 ether;
    // uint256 public maxSupply = 555;

    constructor(address[] memory _payTo, uint256[] memory _shares)
        ERC1155("")
        PaymentSplitter(_payTo, _shares)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(uint256 _id, uint256 _amount) public payable
    {
        require(msg.value == ( _tokenPrice[_id] * _amount), "Error : the price you set is incorrect.");
        require(_tokenSupply[_id] > 0, "Non existant token");
        require(totalSupply(_id) + _amount <= _tokenSupply[_id], "Max amount of mint reached.");
        require(balanceOf(msg.sender, _id) + _amount <= 5, "You can possess a maximum of 5 items.");
        _mint(msg.sender, _id, _amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }

    function addToken(uint256 tokenId, string memory tokenURI, uint256 tokenPrice, uint256 tokenSupply) public onlyOwner {
        require(exists(tokenId) == false, "Token ID already exists");

        _tokenURI[tokenId] = tokenURI;
        _tokenPrice[tokenId] = tokenPrice;
        _tokenSupply[tokenId] = tokenSupply;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}