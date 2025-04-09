// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";         // Access control
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";   // Reentrancy protection
import "@openzeppelin/contracts/security/Pausable.sol";          // Emergency pause
import "@openzeppelin/contracts/utils/math/SafeMath.sol";        // Safe arithmetic operations
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";           // ERC20 interface

contract SecureStaking is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    IERC20 public stakingToken;         // ERC20 token used for staking (ACC-20)
    uint256 public totalStaked;           // Total tokens staked
    uint256 public rewardRate;            // Reward rate per block
    uint256 public lastUpdateBlock;       // Last block when rewards were updated
    uint256 public rewardPerTokenStored;  // Cumulative reward per token stored
    uint256 public constant MIN_STAKE_AMOUNT = 1 * 10**18; // Minimum stake (e.g. 1 token)

    struct Staker {
        uint256 balance;              // Amount staked
        uint256 rewardPerTokenPaid;   // Reward already paid
        uint256 rewards;              // Accumulated rewards (pending claim)
    }

    mapping(address => Staker) public stakers;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _stakingToken, uint256 _rewardRate) {
        require(_stakingToken != address(0), "Invalid token address");
        require(_rewardRate > 0, "Reward rate must be positive");
        stakingToken = IERC20(_stakingToken);
        rewardRate = _rewardRate;
        lastUpdateBlock = block.number;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        if (account != address(0)) {
            stakers[account].rewards = earned(account);
            stakers[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        require(_rewardRate > 0, "Reward rate must be positive");
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        rewardRate = _rewardRate;
    }

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount >= MIN_STAKE_AMOUNT, "Amount below minimum stake");
        totalStaked = totalStaked.add(amount);
        stakers[msg.sender].balance = stakers[msg.sender].balance.add(amount);
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw zero");
        require(stakers[msg.sender].balance >= amount, "Insufficient balance");
        totalStaked = totalStaked.sub(amount);
        stakers[msg.sender].balance = stakers[msg.sender].balance.sub(amount);
        require(stakingToken.transfer(msg.sender, amount), "Token transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(stakers[msg.sender].balance);
        claimReward();
    }

    function claimReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = stakers[msg.sender].rewards;
        if (reward > 0) {
            stakers[msg.sender].rewards = 0;
            require(stakingToken.transfer(msg.sender, reward), "Reward transfer failed");
            emit RewardPaid(msg.sender, reward);
        }
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            block.number.sub(lastUpdateBlock).mul(rewardRate).mul(1e18).div(totalStaked)
        );
    }

    function earned(address account) public view returns (uint256) {
        return stakers[account].balance
            .mul(rewardPerToken().sub(stakers[account].rewardPerTokenPaid))
            .div(1e18)
            .add(stakers[account].rewards);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
