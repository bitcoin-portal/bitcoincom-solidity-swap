// SPDX-License-Identifier: BCOM

// ropstenAddress: 0x0a180a76e4466bf68a7f86fb029bed3cccfaaac5
// path: ["0x0a180a76e4466bf68a7f86fb029bed3cccfaaac5","0xaD6D458402F60fD3Bd25163575031ACDce07538D"]

pragma solidity =0.8.19;

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
        address _dst,
        uint256 _wad
    )
        external
        returns (bool)
    {
        balanceOf[msg.sender] =
        balanceOf[msg.sender] - _wad;

        balanceOf[_dst] =
        balanceOf[_dst] + _wad;

        emit Transfer(
            msg.sender,
            _dst,
            _wad
        );

        return true;
    }

    function transferFrom(
        address _src,
        address _dst,
        uint256 _wad
    )
        external
        returns (bool)
    {
        allowance[_src][msg.sender] =
        allowance[_src][msg.sender] - _wad;

        balanceOf[_src] =
        balanceOf[_src] - _wad;

        balanceOf[_dst] =
        balanceOf[_dst] + _wad;

        emit Transfer(
            _src,
            _dst,
            _wad
        );

        return true;
    }
}
