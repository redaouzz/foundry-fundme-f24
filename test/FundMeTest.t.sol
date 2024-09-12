// SPDX-License-Identifier : MIT

pragma solidity ^0.8.18;

import {Test} from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test, DeployFundMe {
    FundMe fundme;

    address alice = makeAddr("alice");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(alice, STARTING_BALANCE);
    }

    function testDemo() public {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWIthoutEnoughETH() public {
        vm.expectRevert(); // <- The next line after this one should revert! If not test fails.
        fundme.fund(); // <- We send 0 value
    }

    function testFundUpdatesFundDataStructure() public {
        vm.prank(alice);
        fundme.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(alice);
        fundme.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundme.getFunder(0);
        assertEq(funder, alice);
    }

    modifier funded() {
        vm.prank(alice);
        fundme.fund{value: SEND_VALUE}();
        assert(address(fundme).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawFromASingleFunderCheaper() public funded {
        //Arrange
        uint256 startingFundMeBalance = address(fundme).balance;
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();

        //Act
        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Withdraw consummed: %d gas", gasUsed);

        //Assert
        uint256 endingFundMeBalance = address(fundme).balance;
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromASingleFunder() public funded {
        //Arrange
        uint256 startingFundMeBalance = address(fundme).balance;
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();

        //Act
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Withdraw consummed: %d gas", gasUsed);

        //Assert
        uint256 endingFundMeBalance = address(fundme).balance;
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundme).balance;
        uint256 startingOwnerBalance = fundme.getOwner().balance;

        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        assert(address(fundme).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundme.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundme.getOwner().balance - startingOwnerBalance
        );
    }
}
