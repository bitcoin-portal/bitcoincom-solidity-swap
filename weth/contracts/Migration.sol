pragma solidity ^0.4.18;

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    function migration() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }
}
