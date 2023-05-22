// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleSign is Ownable, ERC721A {
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

    function checkMint(uint256 allowedAmount, bytes32[] memory proofs, uint256 amount) external payable {
        checkSignature(allowedAmount, proofs);
        checkAllowlist(allowedAmount, amount);
        _mint(msg.sender, amount);
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Merkle Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    bytes32 internal root;

    function setRoot(bytes32 newRoot) external onlyOwner {
        assembly {
            sstore(root.slot, newRoot)
        }
    }

    function checkSignature(uint256 allowedAmount, bytes32[] memory proofs) internal view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, allowedAmount));

        if (MerkleProof.verify(proofs, root, leaf) == false) {
            assembly {
                mstore(0x00, 0x3d693ada) // NotAllowed()
                revert(0x1c, 0x04)
            }
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Check Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    function checkAllowlist(uint256 allowedAmount, uint256 amount) internal {
        uint256 mintedAmount = ERC721A._getAux(msg.sender);

        assembly {
            // check count : mintedAmount + amount =< allowedAmount
            if gt(add(mintedAmount, amount), allowedAmount) {
                mstore(0x00, 0x21e8d9da) // OverAllocate()
                revert(0x1c, 0x04)
            }
        }

        ERC721A._setAux(msg.sender, uint64(mintedAmount + amount));
    }
}
