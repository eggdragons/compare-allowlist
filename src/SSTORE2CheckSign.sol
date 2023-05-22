// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SSTORE2CheckSign is Ownable, ERC721A {
    uint256 private constant _MASK_UINT8 = 0xff;

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
    SSTORE2 Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    mapping(uint256 => address) public allowlists;
    uint256 private constant _MAX_ALLOWLIST = 1200;

    function setAllowlists(bytes memory data, uint256 allowlistId) external onlyOwner {
        address pointer = SSTORE2.write(data);
        updateAllowlists(pointer, allowlistId);
    }

    function updateAllowlists(address pointer, uint256 allowlistId) public onlyOwner {
        // allowlists[allowlistId] = pointer;
        assembly {
            // get pointer from allowlists
            mstore(0x20, allowlists.slot)
            mstore(0x00, allowlistId)
            let slot := keccak256(0x00, 0x40)
            sstore(slot, pointer)
        }
    }

    function getAllowlist(address pointer) public view returns (bytes memory) {
        return SSTORE2.read(pointer);
    }

    function getAllowlists(uint256 index) public view returns (address user, uint256 allowedAmount) {
        address pointer;
        uint256 start;

        assembly {
            // get start position
            start := mul(mod(index, _MAX_ALLOWLIST), 21)

            // get pointer from allowlists
            mstore(0x20, allowlists.slot)
            mstore(0x00, div(index, _MAX_ALLOWLIST))
            let slot := keccak256(0x00, 0x40)
            pointer := sload(slot)
        }
        bytes memory data = SSTORE2.read(pointer, start, start + 21);
        assembly {
            let v := mload(add(data, 0x20))

            user := shr(96, v)
            allowedAmount := and(_MASK_UINT8, shr(88, v))
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
