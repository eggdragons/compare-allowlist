// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";

contract NonCheckSign is ERC721A {
    constructor() ERC721A("test", "TT") {}

    /* /////////////////////////////////////////////////////////////////////////////
    main function
    ///////////////////////////////////////////////////////////////////////////// */

    function nonCheckMint(uint256 amount) external payable {
        _mint(msg.sender, amount);
    }
}
