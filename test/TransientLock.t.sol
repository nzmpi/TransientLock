// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TransientLock.sol";

contract TestTransientLock is Test {
    enum FallbackToCall {
        None,
        EntryOne,
        EntryTwo,
        TwoThenOne,
        OneThenTwo
    }

    FallbackToCall toCall;
    TransientLock lock;

    function setUp() public {
        lock = new TransientLock();
        delete toCall;
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
        } 
    }
}
