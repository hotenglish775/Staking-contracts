// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ACCToken is ERC20, Ownable {
    uint256 public maxTxAmount; // Maximum allowable transfer amount per transaction.
    mapping(address => bool) public blacklist; // Addresses prohibited from transfers.

    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event MaxTxAmountUpdated(uint256 newMaxTxAmount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 _maxTxAmount
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        maxTxAmount = _maxTxAmount;
    }

    // Override the _transfer function to enforce anti-rugpull checks.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(!blacklist[sender] && !blacklist[recipient], "ACCToken: Blacklisted address");
        require(amount <= maxTxAmount, "ACCToken: Transfer exceeds max transaction limit");
        super._transfer(sender, recipient, amount);
    }

    // Update the blacklist status for an address.
    function updateBlacklist(address account, bool isBlacklisted) external onlyOwner {
        blacklist[account] = isBlacklisted;
        emit BlacklistUpdated(account, isBlacklisted);
    }

    // Update the maximum transaction amount.
    function updateMaxTxAmount(uint256 newMaxTxAmount) external onlyOwner {
        maxTxAmount = newMaxTxAmount;
        emit MaxTxAmountUpdated(newMaxTxAmount);
    }
}
