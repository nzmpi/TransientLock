## Transient Lock

An example of a lock that uses `transient` storage for its reentrancy guard.

The contract is implemented in [src/TransientLock.sol](src/TransientLock.sol).
The tests are in [tests/TransientLock.t.sol](tests/TransientLock.t.sol).

## How to use

 - Use `git clone git@github.com:nzmpi/TransientLock.git && cd TransientLock`.

 - Run `forge test -vv` (you need to install [Foundry](https://book.getfoundry.sh/getting-started/installation) first).

 You can notice that using `transient` storage uses almost 50% less gas than using cold `persistent` storage. But uses more gas than using warm storage.