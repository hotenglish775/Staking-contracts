// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SecureDeployment is Ownable, Pausable {
    mapping(bytes32 => bool) public bannedCodeHashes;
    
    event ContractDeployed(address indexed deployer, address indexed contractAddress, bytes32 indexed codeHash);
    event CodeHashBanned(bytes32 indexed codeHash);
    event CodeHashUnbanned(bytes32 indexed codeHash);
    
    constructor() Ownable(msg.sender) {}
    
    // Ban a specific code hash.
    function banCodeHash(bytes32 codeHash) external onlyOwner {
        require(codeHash != bytes32(0), "SecureDeployment: cannot ban empty code hash");
        require(!bannedCodeHashes[codeHash], "SecureDeployment: code hash already banned");
        
        bannedCodeHashes[codeHash] = true;
        emit CodeHashBanned(codeHash);
    }
    
    // Remove a banned code hash.
    function unbanCodeHash(bytes32 codeHash) external onlyOwner {
        require(bannedCodeHashes[codeHash], "SecureDeployment: code hash not banned");
        
        bannedCodeHashes[codeHash] = false;
        emit CodeHashUnbanned(codeHash);
    }
    
    // Deploy a new contract after ensuring its bytecode is not banned.
    function deployContract(bytes calldata code) external whenNotPaused returns (address addr) {
        require(code.length > 0, "SecureDeployment: empty code");
        
        bytes32 codeHash = keccak256(code);
        require(!bannedCodeHashes[codeHash], "SecureDeployment: code hash is banned");
        
        assembly {
            addr := create(0, add(code.offset, 32), code.length)
        }
        require(addr != address(0), "SecureDeployment: deployment failed");
        
        emit ContractDeployed(msg.sender, addr, codeHash);
        return addr;
    }
    
    // Pause contract deployments
    function pause() external onlyOwner {
        _pause();
    }
    
    // Unpause contract deployments
    function unpause() external onlyOwner {
        _unpause();
    }
}
