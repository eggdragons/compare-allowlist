// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EcdsaSign is Ownable, ERC721A {
    using ECDSA for bytes32;

    uint256 private constant MAX_INT = (1 << 256) - 1;

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

    function checkMint(uint256 index, uint256 allowedAmount, uint256 amount, bytes memory _signature)
        external
        payable
    {
        checkSignature(index, allowedAmount, _signature);
        checkAllowlist(index, allowedAmount, amount);
        _mint(msg.sender, amount);
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Ecdsa Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    function checkSignature(uint256 index, uint256 allowedAmount, bytes memory _signature) internal view {
        bytes32 message;
        assembly {
            mstore(0x00, shl(224, index)) // uint32 index
            mstore(0x04, shl(96, caller())) // address msg.sender
            mstore(0x18, shl(240, allowedAmount)) // uint16 allowedAmount
            message := keccak256(0x00, 26)

            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, message)
            message := keccak256(0x00, 0x3c)
        }

        if (checkAddress != message.recover(_signature)) {
            assembly {
                mstore(0x00, 0x3d693ada) // NotAllowed()
                revert(0x1c, 0x04)
            }
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Bit checker setting
    ///////////////////////////////////////////////////////////////////////////// */

    address internal checkAddress;

    function setCheckAddress(address newAddress) external onlyOwner {
        assembly {
            sstore(checkAddress.slot, newAddress)
        }
    }

    // bitChecker
    mapping(uint256 => uint256) internal checker;

    function setCheckers(uint256[] memory bitChecker) external onlyOwner {
        assembly {
            for {
                let checkerSlot := checker.slot

                // data.length
                let len := mload(bitChecker)

                // counter
                let cc

                // memory counter bitChecker.value
                let mc := add(bitChecker, 0x20)

                let slot
                let value
            } lt(cc, len) {
                cc := add(cc, 1)
                mc := add(mc, 0x20)
            } {
                // get target slot
                mstore(0x00, cc)
                mstore(0x20, checkerSlot)
                slot := keccak256(0, 64)

                // load bitChecker.value
                value := mload(mc)

                // value = 0001111111....
                value := sub(shl(sub(256, value), 1), 1)

                // write checker
                sstore(slot, value)
            }
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Check Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    function checkAllowlist(uint256 index, uint256 allowedAmount, uint256 amount) internal {
        assembly {
            function getBitCounts(_x) -> _y {
                let isMax := eq(_x, MAX_INT)
                _x := sub(_x, and(shr(1, _x), div(MAX_INT, 3)))
                _x := add(and(_x, div(MAX_INT, 5)), and(shr(2, _x), div(MAX_INT, 5)))
                _x := and(add(_x, shr(4, _x)), div(MAX_INT, 17))
                _y := or(shl(8, isMax), shr(248, mul(_x, div(MAX_INT, 255))))
            }

            let slot := div(index, 256)
            let offset := mod(index, 256)

            if gt(add(offset, allowedAmount), 256) {
                mstore(0x00, 0xd2ade556) // IncorrectValue()
                revert(0x1c, 0x04)
            }

            // load bitChecker
            mstore(0x00, slot)
            mstore(0x20, checker.slot)
            let targetSlot := keccak256(0, 64)
            let value := sload(targetSlot)

            let x := and(shr(offset, value), sub(shl(allowedAmount, 1), 1))

            // remainingAmount = allowedAmount - mintedAmount
            let remainingAmount := getBitCounts(x)

            // check amount
            if lt(remainingAmount, amount) {
                mstore(0x00, 0x21e8d9da) // OverAllocate()
                revert(0x1c, 0x04)
            }

            // checker rewrite
            let mask := shl(offset, sub(shl(allowedAmount, 1), 1))
            x := shl(offset, and(x, sub(shl(sub(remainingAmount, amount), 1), 1)))

            value := and(value, not(mask))
            x := or(x, value)
            sstore(targetSlot, x)
        }
    }
}
