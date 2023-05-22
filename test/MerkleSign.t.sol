// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "helper/TestHelpers.t.sol";
import "contracts/MerkleSign.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// forge test --match-contract MerkleSignTest --match-test testGasReportCheckMintNormal -vvvvv --gas-report

// forge snapshot --match-test testCheck
// forge inspect MerkleSign storage --pretty

contract MockMerkleSign is MerkleSign {
    function getRoot() public view returns (bytes32) {
        return root;
    }
}

contract MerkleSignTest is TestHelpers {
    using Strings for uint256;
    using stdJson for string;
    using stdStorage for StdStorage;

    // setting
    uint256 _testLen = sampleNumber;

    // attenstion name sort ASC
    struct Json {
        uint256 allowedAmount;
        bytes32[] proofs;
        address user;
    }

    struct SettingsJson {
        uint256[] bitChecker;
        address signerAddress;
    }

    MockMerkleSign public testContract;

    function setUp() public onlyOwner {
        testContract = new MockMerkleSign();
    }

    function testSetRoot(bytes32 newRoot) public onlyOwner {
        testContract.setRoot(newRoot);
        assertEq(newRoot, testContract.getRoot());
    }

    function testCheckMintNormal() public {
        // test setting
        uint256 len = _testLen;

        // set bitChecker / signerAddress
        helperSetConfig(len);

        // import signDatas
        string memory path = string(abi.encodePacked("./data/merkle/merkleDatas", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);

                testContract.checkMint(result.allowedAmount, result.proofs, result.allowedAmount);

                vm.stopPrank();
                ++i;
            }
        }
    }

    function testGasReportCheckMintNormal() public {
        // test setting
        uint256 len = _testLen;

        // import data
        bytes32 root = helperCreateData(len);

        vm.startPrank(owner);

        // check gas start
        startGas = gasleft();

        // set root
        testContract.setRoot(root);

        // check gas stop
        gasUsed = startGas - gasleft();
        gasUsedForSettings = gasUsed;

        vm.stopPrank();

        // import signDatas
        string memory path = string(abi.encodePacked("./data/merkle/merkleDatas", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                // check gas start
                startGas = gasleft();

                vm.startPrank(result.user);

                testContract.checkMint(result.allowedAmount, result.proofs, result.allowedAmount);

                // check gas stop
                gasUsed = startGas - gasleft();
                gasUsedForFunctions = gasUsedForFunctions + gasUsed;

                totalAmounts = totalAmounts + result.allowedAmount;

                vm.stopPrank();
                ++i;
            }
        }
        createGasReport("MerkleSign", len, gasUsedForSettings, gasUsedForFunctions, totalAmounts);
    }

    function testCheckMintOneMore(uint8 oneMoreAmount) public {
        vm.assume(oneMoreAmount > 0);

        // test setting
        uint256 len = _testLen;

        // set bitChecker / signerAddress
        helperSetConfig(len);

        // import signDatas
        string memory path = string(abi.encodePacked("./data/merkle/merkleDatas", len.toString(), ".json"));

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
                    testContract.checkMint(result.allowedAmount, result.proofs, result.allowedAmount - oneMoreAmount);

                    // one more mint
                    testContract.checkMint(result.allowedAmount, result.proofs, oneMoreAmount);
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
        string memory path = string(abi.encodePacked("./data/merkle/merkleDatas", len.toString(), ".json"));

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
                    testContract.checkMint(result.allowedAmount, result.proofs, result.allowedAmount + 1);
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
        string memory path = string(abi.encodePacked("./data/merkle/merkleDatas", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);

                testContract.checkMint(result.allowedAmount, result.proofs, result.allowedAmount);

                // one more mint --> error OverAllocate()
                vm.expectRevert(0x21e8d9da);
                testContract.checkMint(result.allowedAmount, result.proofs, 1);

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
        string memory path = string(abi.encodePacked("./data/merkle/merkleDatas", len.toString(), ".json"));

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
                    testContract.checkMint(result.allowedAmount, result.proofs, result.allowedAmount);
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
        string memory path = string(abi.encodePacked("./data/merkle/root", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);
        bytes32 root = bytes32(vm.parseJson(readJson));

        testContract.setRoot(root);
    }

    function helperCreateData(uint256 len) public view returns (bytes32 root) {
        string memory path = string(abi.encodePacked("./data/merkle/root", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);
        root = bytes32(vm.parseJson(readJson));

        return root;
    }
}
