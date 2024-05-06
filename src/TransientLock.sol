// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract TransientLock {
    // keccak256(abi.encode(uint256(keccak256("GUARD_ONE_SLOT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant GUARD_ONE_SLOT = 0x9de0e50e7b1fe36e32de5280e28edb4ee6199700547d4e1fd5dc6dff83e8c900;
    // keccak256(abi.encode(uint256(keccak256("GUARD_TWO_SLOT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant GUARD_TWO_SLOT = 0x4fc41fedccfba315508e0a14e596c2ab309fee6028fcdcd7de0ca48de87bf900;
    // keccak256(abi.encode(uint256(keccak256("ALLOWANCE_SLOT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant ALLOWANCE_SLOT = 0x119a13983cfc550cc0903b273f26f234320a83950fe37e016c851dea0a607100;
    bool public isEntryOneCalled;
    bool public isEntryTwoCalled;

    error ReentryOne();
    error ReentryTwo();
    error WrongAllowance();

    modifier guardOne() {
        bytes32 selector = bytes32(ReentryOne.selector);
        assembly {
            if tload(GUARD_ONE_SLOT) {
                mstore(0, selector)
                revert(0, 4)
            }
            tstore(GUARD_ONE_SLOT, 1)
        }
        _;
        assembly {
            tstore(GUARD_ONE_SLOT, 0)
        }
    }

    modifier guardTwo() {
        bytes32 selector = bytes32(ReentryTwo.selector);
        assembly {
            if tload(GUARD_TWO_SLOT) {
                mstore(0, selector)
                revert(0, 4)
            }
            tstore(GUARD_TWO_SLOT, 1)
        }
        _;
        assembly {
            tstore(GUARD_TWO_SLOT, 0)
        }
    }

    function entryOne() external guardOne {
        isEntryOneCalled = true;
        (bool s, bytes memory data) = msg.sender.call("call fallback");
        bytes32 data32 = bytes32(data);
        if (!s) {
            assembly {
                mstore(0, data32)
                revert(0, 4)
            }
        }
    }

    function entryTwo() external guardTwo {
        isEntryTwoCalled = true;
        (bool s, bytes memory data) = msg.sender.call("call fallback");
        bytes32 data32 = bytes32(data);
        if (!s) {
            assembly {
                mstore(0, data32)
                revert(0, 4)
            }
        }
    }

    /**
     * @dev an approve pattern entry
     * @param amount - amount to approve
     */
    function entryThree(uint256 amount) external {
        // mapping(address => uint256) allowance;
        bytes32 slot = keccak256(abi.encode(msg.sender, ALLOWANCE_SLOT));
        assembly {
            tstore(slot, amount)
        }

        // do a swap, flashloan, transferFrom, etc.
        (bool s,) = msg.sender.call("call fallback");
        if (!s) revert WrongAllowance();

        // delete allowance for safety
        assembly {
            tstore(slot, 0)
        }
    }

    function allowance(address owner) public view returns (uint256 amount) {
        bytes32 slot = keccak256(abi.encode(owner, ALLOWANCE_SLOT));
        assembly {
            amount := tload(slot)
        }
    }
}
