// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "helper/TestHelpers.t.sol";
import "contracts/SSTORE2CheckSign.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// forge test --match-contract SSTORE2CheckSignTest --match-test testGasReportCheckMintNormal -vvvvv --gas-report

contract SSTORE2CheckSignTest is TestHelpers {
    using stdJson for string;
    using Strings for uint256;

    // setting
    uint256 _testLen = sampleNumber;

    // 21bytes * 1170 = 24,570bytes < 24,576 bytes
    uint256 _MAX_ALLOWLIST = 1170;

    // attenstion name sort ASC
    struct Json {
        uint256 allowedAmount;
        address user;
    }

    SSTORE2CheckSign public testContract;

    function setUp() public onlyOwner {
        testContract = new SSTORE2CheckSign();
    }

    /* /////////////////////////////////////////////////////////////////////////////
    SSTORE2 Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    function testSetGetAllowlists() public {
        // setting
        uint256 len = _testLen;

        // setAllowlists
        (address[] memory addrs, uint256[] memory allowedAmounts) = helperSetBulkAllowlists(len);

        // check allowlist
        for (uint256 i = 0; i < len;) {
            (address user, uint256 allowedAmount) = testContract.getAllowlists(i);
            assertEq(user, addrs[i]);
            assertEq(allowedAmount, allowedAmounts[i]);
            ++i;
        }
    }

    function testCheckMintNormal() public {
        // setting
        uint256 len = _testLen;

        // setAllowlists
        helperSetConfig(len);

        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);
                testContract.checkMint(i, result.allowedAmount);
                vm.stopPrank();
                ++i;
            }
        }
    }

    function testGasReportCheckMintNormal() public {
        // setting
        uint256 len = _testLen;

        // import data
        (bytes memory data, uint256 div) = helperCreateData(len);

        vm.startPrank(owner);

        // check gas start
        startGas = gasleft();

        // set allowlist
        testContract.setAllowlists(data, div);

        // check gas stop
        gasUsed = startGas - gasleft();
        gasUsedForSettings = gasUsed;

        vm.stopPrank();

        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);

                // check gas start
                startGas = gasleft();

                testContract.checkMint(i, result.allowedAmount);

                // check gas stop
                gasUsed = startGas - gasleft();
                gasUsedForFunctions = gasUsedForFunctions + gasUsed;

                totalAmounts = totalAmounts + result.allowedAmount;

                vm.stopPrank();
                ++i;
            }
        }
        createGasReport("SSTORE2CheckSign", len, gasUsedForSettings, gasUsedForFunctions, totalAmounts);
    }

    function testCheckMintOneMore(uint8 oneMoreAmount) public {
        vm.assume(oneMoreAmount > 0);

        // test setting
        uint256 len = _testLen;

        // set bitChecker / signerAddress
        helperSetConfig(len);

        // import signDatas
        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);

                if (result.allowedAmount > oneMoreAmount) {
                    testContract.checkMint(i, result.allowedAmount - oneMoreAmount);

                    // one more mint
                    testContract.checkMint(i, oneMoreAmount);
                }

                vm.stopPrank();
                ++i;
            }
        }
    }

    function testCheckMintOverAllocate() public {
        // test setting
        uint256 len = _testLen;

        // set bitChecker / signerAddress
        helperSetConfig(len);

        // import signDatas
        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);

                if (result.allowedAmount < 256) {
                    // error OverAllocate()
                    vm.expectRevert(0x21e8d9da);

                    // over mint
                    testContract.checkMint(i, result.allowedAmount + 1);
                }

                vm.stopPrank();
                ++i;
            }
        }
    }

    function testCheckMintOverAllocateOneMore() public {
        // test setting
        uint256 len = _testLen;

        // set bitChecker / signerAddress
        helperSetConfig(len);

        // import signDatas
        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);

                testContract.checkMint(i, result.allowedAmount);

                // one more mint --> error OverAllocate()
                vm.expectRevert(0x21e8d9da);
                testContract.checkMint(i, 1);

                vm.stopPrank();
                ++i;
            }
        }
    }

    function testCheckMintNotAllower(address notAllower) public {
        vm.assume(notAllower != zeroAddress);

        // test setting
        uint256 len = _testLen;

        // set bitChecker / signerAddress
        helperSetConfig(len);

        // import signDatas
        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(notAllower);
                if (result.user != notAllower) {
                    // error NotAllowed()
                    vm.expectRevert(0x3d693ada);
                    testContract.checkMint(i, result.allowedAmount);
                }

                vm.stopPrank();
                ++i;
            }
        }
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Helper
    ///////////////////////////////////////////////////////////////////////////// */

    function helperSetConfig(uint256 len) public onlyOwner {
        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        bytes memory data;

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                data = abi.encodePacked(data, result.user, uint8(result.allowedAmount));

                // set allowlist
                if ((i + 1) % _MAX_ALLOWLIST == 0) {
                    testContract.setAllowlists(data, i / _MAX_ALLOWLIST);
                    data = "";
                }

                ++i;
            }
        }

        // set allowlist
        uint256 div = len / _MAX_ALLOWLIST;
        testContract.setAllowlists(data, div);
    }

    function helperCreateData(uint256 len) public returns (bytes memory data, uint256 div) {
        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                data = abi.encodePacked(data, result.user, uint8(result.allowedAmount));

                // set allowlist
                if ((i + 1) % _MAX_ALLOWLIST == 0) {
                    testContract.setAllowlists(data, i / _MAX_ALLOWLIST);
                    data = "";
                }

                ++i;
            }
        }

        // set allowlist
        div = len / _MAX_ALLOWLIST;
        return (data, div);
    }

    function helperSetBulkAllowlists(uint256 len)
        public
        onlyOwner
        returns (address[] memory addrs, uint256[] memory allowedAmounts)
    {
        string memory path = string(abi.encodePacked("./data/allowlist/allowlists", len.toString(), ".json"));

        bytes memory data;

        addrs = new address[](len);
        allowedAmounts = new uint256[](len);

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                data = abi.encodePacked(data, result.user, uint8(result.allowedAmount));

                // set allowlist
                if ((i + 1) % _MAX_ALLOWLIST == 0) {
                    testContract.setAllowlists(data, i / _MAX_ALLOWLIST);
                    data = "";
                }

                addrs[i] = result.user;
                allowedAmounts[i] = result.allowedAmount;

                ++i;
            }
        }

        // set allowlist
        uint256 div = len / _MAX_ALLOWLIST;
        testContract.setAllowlists(data, div);
    }
}
