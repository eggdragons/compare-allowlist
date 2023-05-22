// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MappingCheckSign is Ownable, ERC721A {
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

    function checkMint(uint256 amount) external payable {
        checkAllowlist(amount);
        _mint(msg.sender, amount);
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Mapping Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    mapping(address => uint256) public allowlists;

    // allowlists[user] = allowedAmount
    function setAllowlists(address user, uint256 allowedAmount) external onlyOwner {
        assembly {
            // set pointer to Allowlists
            mstore(0x00, user)
            mstore(0x20, allowlists.slot)
            sstore(keccak256(0x00, 0x40), allowedAmount)
        }
    }

    // for loop allowlists[user] = allowedAmount
    function setBulkAllowlists(bytes memory data) external onlyOwner {
        assembly {
            function f(x, slot) {
                // set pointer to Allowlists
                mstore(0x00, shr(96, x))
                mstore(0x20, slot)
                sstore(keccak256(0x00, 0x40), and(0xff, shr(88, x)))
            }

            let slot := allowlists.slot

            for {
                // data.length
                let len := mload(data)

                // memory counter
                let mc := add(data, 0x20)
            } 1 { mc := add(mc, 21) } {
                len := sub(len, 21)
                f(mload(mc), slot)

                if iszero(len) { break }
            }
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Check Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    function checkAllowlist(uint256 amount) public {
        uint256 mintedAmount = ERC721A._getAux(msg.sender);

        assembly {
            // get allowedAmount
            mstore(0x00, caller())
            mstore(0x20, allowlists.slot)
            let allowedAmount := sload(keccak256(0x00, 0x40))

            // check count : mintedAmount + amount =< allowedAmount
            if gt(add(mintedAmount, amount), allowedAmount) {
                mstore(0x00, 0x21e8d9da) // OverAllocate()
                revert(0x1c, 0x04)
            }
        }

        ERC721A._setAux(msg.sender, uint64(mintedAmount + amount));
    }
}
