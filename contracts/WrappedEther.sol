// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

contract WrappedEther {

    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8  public decimals = 18;

    event Approval(
        address indexed src,
        address indexed guy,
        uint256 wad
    );

    event Transfer(
        address indexed src,
        address indexed dst,
        uint256 wad
    );

    event Deposit(
        address indexed dst,
        uint256 wad
    );

    event Withdrawal(
        address indexed src,
        uint256 wad
    );

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    receive() external payable {
        deposit();
    }

    function deposit()
        public
        payable
    {
        balanceOf[msg.sender] =
        balanceOf[msg.sender] + msg.value;

        emit Deposit(
            msg.sender,
            msg.value
        );
    }

    function withdraw(
        uint256 _wad
    )
        public
    {
        balanceOf[msg.sender] =
        balanceOf[msg.sender] - _wad;

        payable(msg.sender).transfer(_wad);

        emit Withdrawal(
            msg.sender,
            _wad
        );
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function approve(
        address _guy,
        uint256 _wad
    )
        public
        returns (bool)
    {
        allowance[msg.sender][_guy] = _wad;
        emit Approval(msg.sender, _guy, _wad);
        return true;
    }

    function transfer(
        address dst,
        uint wad
    )
        public
        returns (bool)
    {
        return transferFrom(
            msg.sender,
            dst,
            wad
        );
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    )
        public
        returns (bool)
    {
        allowance[src][msg.sender] =
        allowance[src][msg.sender] - wad;

        balanceOf[src] =
        balanceOf[src] - wad;

        balanceOf[dst] =
        balanceOf[dst] - wad;

        emit Transfer(
            src,
            dst,
            wad
        );

        return true;
    }
}
