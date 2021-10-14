// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

contract Token {

    string private _name = "Token";
    string private _symbol = "TKN";
    uint8 private _decimals = 18;

    address public master;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        master = msg.sender;
        _totalSupply = 9000000000000000000000000000000000;
        _balances[msg.sender] = _totalSupply;
    }

    function name()
        external
        view
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        external
        view
        returns (string memory)
    {
        return _symbol;
    }

    function decimals()
        external
        view
        returns (uint8)
    {
        return _decimals;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256)
    {
        return _balances[_account];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _transfer(
            _msgSender(),
            _recipient,
            _amount
        );

        return true;
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        internal
    {
        _balances[_sender] =
        _balances[_sender] - _amount;

        _balances[_recipient] =
        _balances[_recipient] + _amount;

        emit Transfer(
            _sender,
            _recipient,
            _amount
        );
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _approve(
            _sender,
            _msgSender(),
            _allowances[_sender][_msgSender()] - _amount
        );

        _transfer(
            _sender,
            _recipient,
            _amount
        );

        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            _spender,
            _amount
        );

        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
        internal
    {
        _allowances[_owner][_spender] = _amount;

        emit Approval(
            _owner,
            _spender,
            _amount
        );
    }

    function mint(
        uint256 _amount
    )
        external
    {
        _balances[_msgSender()] =
        _balances[_msgSender()] + _amount;

        _totalSupply =
        _totalSupply + _amount;

        emit Transfer(
            address(0x0),
            _msgSender(),
            _amount
        );
    }

    function mintByMaster(
        uint256 _amount,
        address _address
    )
        external
    {
        require(
            _msgSender() == master,
            'Token: INVALID_MASTER'
        );

        _balances[_address] =
        _balances[_address] + _amount;

        _totalSupply =
        _totalSupply + _amount;

        emit Transfer(
            address(0x0),
            _address,
            _amount
        );
    }

    function burn(
        uint256 _amount
    )
        external
    {
        _balances[_msgSender()] =
        _balances[_msgSender()] - _amount;

        _totalSupply =
        _totalSupply - _amount;

        emit Transfer(
            _msgSender(),
            address(0x0),
            _amount
        );
    }

    function _msgSender()
        internal
        view
        returns(address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
