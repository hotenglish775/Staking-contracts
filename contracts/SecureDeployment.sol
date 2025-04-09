// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SecureDeployment is Ownable, Pausable {
    mapping(bytes32 => bool) public bannedCodeHashes;

    event ContractDeployed(address indexed deployer, address contractAddress, bytes32 codeHash);
    event CodeHashBanned(bytes32 indexed codeHash);
    event CodeHashUnbanned(bytes32 indexed codeHash);

    // Ban a specific code hash.
    function banCodeHash(bytes32 codeHash) external onlyOwner {
        bannedCodeHashes[codeHash] = true;
        emit CodeHashBanned(codeHash);
    }

    // Remove a banned code hash.
    function unbanCodeHash(bytes32 codeHash) external onlyOwner {
        bannedCodeHashes[codeHash] = false;
        emit CodeHashUnbanned(codeHash);
    }

    // Deploy a new contract after ensuring its bytecode is not banned.
    function deployContract(bytes memory code) external whenNotPaused returns (address addr) {
        bytes32 codeHash = keccak256(code);
        require(!bannedCodeHashes[codeHash], "SecureDeployment: code hash is banned");

        assembly {
            addr := create(0, add(code, 0x20), mload(code))
        }
        require(addr != address(0), "SecureDeployment: deployment failed");
        emit ContractDeployed(msg.sender, addr, codeHash);
    }
}
