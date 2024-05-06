## Transient Lock

An example of a lock that uses `transient` storage for its reentrancy guard.

The contract is implemented in [src/TransientLock.sol](src/TransientLock.sol).
The tests are in [test/TransientLock.t.sol](test/TransientLock.t.sol).

## How to use

 - Use `git clone git@github.com:nzmpi/TransientLock.git && cd TransientLock`.

 - Run `forge test -vv` (you need to install
 [Foundry](https://book.getfoundry.sh/getting-started/installation) first).

 You can notice that using `transient` storage for a reentrancy guard uses almost 50%
 less gas than using cold `persistent` storage, but uses more gas than using warm storage.

 However, using `transient` storage for an `approve` pattern tx uses more than 90%
 less gas than using cold `persistent` storage.
