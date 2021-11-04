// SPDX-License-Identifier: BCOM

pragma solidity ^0.8.9;

uint256 constant U256_MAX = 2 ** 256 - 1;
address constant ZERO_ADDRESS = address(0x0);

bytes4 constant TRANSFER = bytes4(
    keccak256(
        bytes(
            'transfer(address,uint256)'
        )
    )
);

bytes4 constant TRANSFER_FROM = bytes4(
    keccak256(
        bytes(
            'transferFrom(address,address,uint256)'
        )
    )
);

function _safeTransfer(
    address _token,
    address _to,
    uint256 _value
) {
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(
            TRANSFER,
            _to,
            _value
        )
    );

    require(
        success == true && (
            data.length == 0 || abi.decode(
                data, (bool)
            )
        ),
        'TRANSFER_FAILED'
    );
}

function _safeTransferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _value
) {
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(
            TRANSFER_FROM,
            _from,
            _to,
            _value
        )
    );

    require(
        success == true && (
            data.length == 0 || abi.decode(
                data, (bool)
            )
        ),
        'TRANSFER_FROM_FAILED'
    );
}

function safeTransferETH(
    address to,
    uint value
) {
    (bool success,) = to.call{
        value: value
    }(new bytes(0));

    require(
        success == true,
        'ETH_TRANSFER_FAILED'
    );
}
