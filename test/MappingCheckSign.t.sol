// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "helper/TestHelpers.t.sol";
import "contracts/MappingCheckSign.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// forge test --match-contract MappingCheckSignTest --match-test testCheckMintNormal -vvvvv --gas-report

// forge snapshot --match-test testSetAllowlistFuzz

contract MappingCheckSignTest is TestHelpers {
    using stdJson for string;
    using Strings for uint256;

    // setting
    uint256 _testLen = sampleNumber;

    // attenstion name sort ASC
    struct Json {
        uint256 allowedAmount;
        address user;
    }

    MappingCheckSign public testContract;

    function setUp() public onlyOwner {
        testContract = new MappingCheckSign();
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Mapping Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    function testSetGetAllowlistsFuzz(address user, uint256 allowedAmount) public onlyOwner {
        testContract.setAllowlists(user, allowedAmount);
        assertEq(testContract.allowlists(user), allowedAmount);
    }

    function testSetGetBulkAllowlists() public {
        // test setting
        uint256 len = _testLen;

        // setAllowlists
        (address[] memory addrs, uint256[] memory allowedAmounts) = helperSetBulkAllowlists(len);

        // check allowlist
        for (uint256 i = 0; i < len;) {
            assertEq(testContract.allowlists(addrs[i]), allowedAmounts[i]);
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
                testContract.checkMint(result.allowedAmount);
                vm.stopPrank();
                ++i;
            }
        }
    }

    function testGasReportCheckMintNormal() public {
        // setting
        uint256 len = _testLen;

        // import data
        bytes memory data = helperCreateData(len);

        vm.startPrank(owner);

        // check gas start
        startGas = gasleft();

        // set allowlist
        testContract.setBulkAllowlists(data);

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

                testContract.checkMint(result.allowedAmount);

                // check gas stop
                gasUsed = startGas - gasleft();
                gasUsedForFunctions = gasUsedForFunctions + gasUsed;

                totalAmounts = totalAmounts + result.allowedAmount;

                vm.stopPrank();
                ++i;
            }
        }

        createGasReport("MappingCheckSign", len, gasUsedForSettings, gasUsedForFunctions, totalAmounts);
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
                    testContract.checkMint(result.allowedAmount - oneMoreAmount);

                    // one more mint
                    testContract.checkMint(oneMoreAmount);
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
                    testContract.checkMint(result.allowedAmount + 1);
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

                testContract.checkMint(result.allowedAmount);

                // one more mint --> error OverAllocate()
                vm.expectRevert(0x21e8d9da);
                testContract.checkMint(1);

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
                    // error OverAllocate()
                    vm.expectRevert(0x21e8d9da);
                    testContract.checkMint(result.allowedAmount);
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
                ++i;
            }
        }

        // set allowlist
        testContract.setBulkAllowlists(data);
    }

    function helperCreateData(uint256 len) public view returns (bytes memory data) {
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
                ++i;
            }
        }

        return data;
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

                addrs[i] = result.user;
                allowedAmounts[i] = result.allowedAmount;

                ++i;
            }
        }

        // set allowlist
        testContract.setBulkAllowlists(data);
    }
}
