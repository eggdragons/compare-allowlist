// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BytesCheckSign is Ownable, ERC721A {
    constructor() ERC721A("test", "TT") {}

    /* /////////////////////////////////////////////////////////////////////////////
    error
    ///////////////////////////////////////////////////////////////////////////// */

    /// @dev OverIndex 0xd2ade556
    error IncorrectValue();

    /// @dev OverAllocate 0x21e8d9da
    error OverAllocate();

    /// @dev msg.sender(caller) is not allowed 0x3d693ada
    error NotAllowed();

    /* /////////////////////////////////////////////////////////////////////////////
    main function
    ///////////////////////////////////////////////////////////////////////////// */

    function nonCheckMint(uint256 amount) external payable {
        _mint(msg.sender, amount);
    }

    function checkMint(uint256 index, uint256 amount) external payable {
        checkAllowlist(index, amount);
        _mint(msg.sender, amount);
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Bytes Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    bytes internal allowlists;

    function setAllowlists(bytes memory data) external onlyOwner {
        allowlists = data;
    }

    function getAllowlists(uint256 index) public view returns (address user, uint256 allowedAmount) {
        bytes memory data = allowlists;
        assembly {
            let len := mload(data)

            // check index =< len
            if lt(len, index) {
                mstore(0x00, 0xd2ade556) // IncorrectValue()
                revert(0x1c, 0x04)
            }

            let value := mload(add(add(data, 0x20), mul(index, 21)))
            user := shr(96, value)
            allowedAmount := shr(248, shl(160, value))
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Check Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    function checkAllowlist(uint256 index, uint256 amount) internal {
        (address user, uint256 allowedAmount) = getAllowlists(index);
        uint256 mintedAmount = ERC721A._getAux(msg.sender);

        assembly {
            // check msg.sender
            if iszero(eq(user, caller())) {
                mstore(0x00, 0x3d693ada) // NotAllowed()
                revert(0x1c, 0x04)
            }
            // check count : mintedAmount + amount =< allowedAmount
            if gt(add(mintedAmount, amount), allowedAmount) {
                mstore(0x00, 0x21e8d9da) // OverAllocate()
                revert(0x1c, 0x04)
            }
        }

        ERC721A._setAux(msg.sender, uint64(mintedAmount + amount));
    }
}
