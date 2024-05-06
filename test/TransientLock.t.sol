// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TransientLock.sol";
import "./utils/ColdPersistentLock.sol";
import "./utils/WarmPersistentLock.sol";

contract TestTransientLock is Test {
    enum FallbackToCall {
        None,
        EntryOne,
        EntryTwo,
        TwoThenOne,
        OneThenTwo,
        EntryThree
    }

    FallbackToCall toCall;
    TransientLock lock;

    function setUp() public {
        lock = new TransientLock();
        delete toCall;
    }

    function test_deployment() public view {
        assertFalse(lock.isEntryOneCalled(), "EntryOne should be false");
        assertFalse(lock.isEntryTwoCalled(), "EntryTwo should be false");
    }

    function test_valid_entryOne() public {
        lock.entryOne();
        assertTrue(lock.isEntryOneCalled(), "EntryOne should be true");
        assertFalse(lock.isEntryTwoCalled(), "EntryTwo should be false");
    }

    function test_valid_entryTwo() public {
        lock.entryTwo();
        assertFalse(lock.isEntryOneCalled(), "EntryOne should be false");
        assertTrue(lock.isEntryTwoCalled(), "EntryTwo should be true");
    }

    function test_valid_entryOneThenTwo() public {
        toCall = FallbackToCall.EntryTwo;
        lock.entryOne();
        assertTrue(lock.isEntryOneCalled(), "EntryOne should be true");
        assertTrue(lock.isEntryTwoCalled(), "EntryTwo should be true");
    }

    function test_valid_entryTwoThenOne() public {
        toCall = FallbackToCall.EntryOne;
        lock.entryTwo();
        assertTrue(lock.isEntryOneCalled(), "EntryOne should be true");
        assertTrue(lock.isEntryTwoCalled(), "EntryTwo should be true");
    }

    function test_valid_another_user_entry() public {
        lock.entryOne();
        vm.prank(makeAddr("another user"));
        lock.entryOne();
        assertTrue(lock.isEntryOneCalled(), "EntryOne should be true");
        assertFalse(lock.isEntryTwoCalled(), "EntryTwo should be false");
    }

    function test_valid_entryThree() public {
        toCall = FallbackToCall.EntryThree;
        lock.entryThree(42);
        assertEq(lock.allowance(address(this)), 0, "Allowance should be 0");
    }

    function test_gas_usage() public {
        // deploying here to make gas comparison fairer
        TransientLock tlock = new TransientLock();
        uint256 gasBefore = gasleft();
        tlock.entryOne();
        uint256 gasAfterTlock = gasBefore - gasleft();

        // the modifier is using cold storage
        ColdPersistentLock cplock = new ColdPersistentLock();
        gasBefore = gasleft();
        cplock.entryOne();
        uint256 gasAfterCpl = gasBefore - gasleft();

        // the modifier is using warm storage
        WarmPersistentLock wplock = new WarmPersistentLock();
        gasBefore = gasleft();
        wplock.entryOne();
        uint256 gasAfterWpl = gasBefore - gasleft();

        assertTrue(tlock.isEntryOneCalled(), "EntryOne in tlock should be true");
        assertTrue(cplock.isEntryOneCalled(), "EntryOne in cplock should be true");
        assertTrue(wplock.isEntryOneCalled(), "EntryOne in wplock should be true");
        uint256 percentageCold = gasAfterTlock * 100 / gasAfterCpl;
        uint256 percentageWarm = gasAfterTlock * 100 / gasAfterWpl;
        assertLe(percentageCold, 60, "Wrong gas usage cold storage");
        assertGe(percentageWarm, 100, "Wrong gas usage warm storage");

        console.log("Reentry gas usage:");
        console.log("tlock = ", gasAfterTlock);
        console.log("cplock = ", gasAfterCpl);
        console.log("%%:", percentageCold);
        console.log("wplock = ", gasAfterWpl);
        console.log("%%:", percentageWarm);

        // APPROVE PATTERN
        gasBefore = gasleft();
        tlock.entryThree(1337);
        gasAfterTlock = gasBefore - gasleft();

        gasBefore = gasleft();
        cplock.entryThree(1337);
        gasAfterCpl = gasBefore - gasleft();
        percentageCold = gasAfterTlock * 100 / gasAfterCpl;
        assertLe(percentageCold, 10, "Wrong approve gas usage cold storage");

        console.log("");
        console.log("Approve gas usage:");
        console.log("tlock = ", gasAfterTlock);
        console.log("cplock = ", gasAfterCpl);
        console.log("%%:", percentageCold);
    }

    function test_invalid_entryOneReentry() public {
        toCall = FallbackToCall.EntryOne;
        vm.expectRevert(TransientLock.ReentryOne.selector);
        lock.entryOne();
        assertFalse(lock.isEntryOneCalled(), "EntryOne should be false");
        assertFalse(lock.isEntryTwoCalled(), "EntryTwo should be false");
    }

    function test_invalid_entryTwoReentry() public {
        toCall = FallbackToCall.EntryTwo;
        vm.expectRevert(TransientLock.ReentryTwo.selector);
        lock.entryTwo();
        assertFalse(lock.isEntryOneCalled(), "EntryOne should be false");
        assertFalse(lock.isEntryTwoCalled(), "EntryTwo should be false");
    }

    function test_invalid_entryOneThenTwoThenOne() public {
        toCall = FallbackToCall.TwoThenOne;
        vm.expectRevert(TransientLock.ReentryOne.selector);
        lock.entryOne();
        assertFalse(lock.isEntryOneCalled(), "EntryOne should be false");
        assertFalse(lock.isEntryTwoCalled(), "EntryTwo should be false");
    }

    function test_invalid_entryTwoThenOneThenTwo() public {
        toCall = FallbackToCall.OneThenTwo;
        vm.expectRevert(TransientLock.ReentryTwo.selector);
        lock.entryTwo();
        assertFalse(lock.isEntryOneCalled(), "EntryOne should be false");
        assertFalse(lock.isEntryTwoCalled(), "EntryTwo should be false");
    }

    function checkAllowance() internal view {
        assertEq(lock.allowance(address(this)), 42, "Allowance should be 42");
    }

    fallback() external {
        if (toCall == FallbackToCall.None) {
            return;
        } else if (toCall == FallbackToCall.EntryOne) {
            delete toCall;
            lock.entryOne();
        } else if (toCall == FallbackToCall.EntryTwo) {
            delete toCall;
            lock.entryTwo();
        } else if (toCall == FallbackToCall.TwoThenOne) {
            toCall = FallbackToCall.EntryOne;
            lock.entryTwo();
        } else if (toCall == FallbackToCall.OneThenTwo) {
            toCall = FallbackToCall.EntryTwo;
            lock.entryOne();
        } else if (toCall == FallbackToCall.EntryThree) {
            delete toCall;
            checkAllowance();
        }
    }
}
