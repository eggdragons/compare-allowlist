// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "helper/TestHelpers.t.sol";
import "contracts/EcdsaSign.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// forge test --match-contract EcdsaSignTest --match-test testGasReportCheckMintNormal -vvvvv --gas-report

// forge snapshot --match-test testCheck
// forge inspect EcdsaSign storage --pretty
contract MockEcdsaSign is EcdsaSign {
    function getChecker(uint256 index) public view returns (uint256) {
        return checker[index];
    }
}

contract EcdsaSignTest is TestHelpers {
    using Strings for uint256;
    using stdJson for string;
    using stdStorage for StdStorage;

    // setting
    uint256 _testLen = sampleNumber;

    // attenstion name sort ASC
    struct Json {
        uint256 allowedAmount;
        uint256 index;
        bytes signature;
        address user;
    }

    struct SettingsJson {
        uint256[] bitChecker;
        address signerAddress;
    }

    MockEcdsaSign public testContract;

    function setUp() public onlyOwner {
        testContract = new MockEcdsaSign();
    }

    uint256[] bitChecker;

    function testSetCheckers() public onlyOwner {
        bitChecker = [3, 192];
        testContract.setCheckers(bitChecker);

        uint256 len = bitChecker.length;
        for (uint256 i; i < len;) {
            assertEq(((1 << (256 - bitChecker[i])) - 1), testContract.getChecker(i));
            ++i;
        }
    }

    function testSetCheckAddress(address newAddress) public onlyOwner {
        testContract.setCheckAddress(newAddress);

        bytes32 checkAddress = vm.load(address(testContract), bytes32(uint256(9)));
        assertEq(address(uint160(uint256(checkAddress))), newAddress);
    }

    function testCheckMintNormal() public {
        // test setting
        uint256 len = _testLen;

        // set bitChecker / signerAddress
        helperSetConfig(len);

        // import signDatas
        string memory path = string(abi.encodePacked("./data/ecdsa/signDatas", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);

                testContract.checkMint(result.index, result.allowedAmount, result.allowedAmount, result.signature);

                vm.stopPrank();
                ++i;
            }
        }
    }

    function testGasReportCheckMintNormal() public {
        // test setting
        uint256 len = _testLen;

        // import data
        address signerAddress = helperCreateData(len);

        vm.startPrank(owner);

        // check gas start
        startGas = gasleft();

        // set bitChecker / signerAddress
        testContract.setCheckers(bitChecker);
        testContract.setCheckAddress(signerAddress);

        // check gas stop
        gasUsed = startGas - gasleft();
        gasUsedForSettings = gasUsed;

        vm.stopPrank();

        // import signDatas
        string memory path = string(abi.encodePacked("./data/ecdsa/signDatas", len.toString(), ".json"));

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

                testContract.checkMint(result.index, result.allowedAmount, result.allowedAmount, result.signature);

                // check gas stop
                gasUsed = startGas - gasleft();
                gasUsedForFunctions = gasUsedForFunctions + gasUsed;

                totalAmounts = totalAmounts + result.allowedAmount;

                vm.stopPrank();
                ++i;
            }
        }

        createGasReport("EcdsaSign", len, gasUsedForSettings, gasUsedForFunctions, totalAmounts);
    }

    function testCheckMintOneMore(uint8 oneMoreAmount) public {
        vm.assume(oneMoreAmount > 0);

        // test setting
        uint256 len = _testLen;

        // set bitChecker / signerAddress
        helperSetConfig(len);

        // import signDatas
        string memory path = string(abi.encodePacked("./data/ecdsa/signDatas", len.toString(), ".json"));

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
                    testContract.checkMint(
                        result.index, result.allowedAmount, result.allowedAmount - oneMoreAmount, result.signature
                    );

                    // one more mint
                    testContract.checkMint(result.index, result.allowedAmount, oneMoreAmount, result.signature);
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
        string memory path = string(abi.encodePacked("./data/ecdsa/signDatas", len.toString(), ".json"));

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
                    testContract.checkMint(
                        result.index, result.allowedAmount, result.allowedAmount + 1, result.signature
                    );
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
        string memory path = string(abi.encodePacked("./data/ecdsa/signDatas", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // check write data === read data
        for (uint256 i; i < len;) {
            unchecked {
                // decode
                bytes memory abiEncodedData = readJson.parseRaw(string(abi.encodePacked("[", i.toString(), "]")));
                Json memory result = abi.decode(abiEncodedData, (Json));

                vm.startPrank(result.user);

                testContract.checkMint(result.index, result.allowedAmount, result.allowedAmount, result.signature);

                // one more mint --> error OverAllocate()
                vm.expectRevert(0x21e8d9da);
                testContract.checkMint(result.index, result.allowedAmount, 1, result.signature);

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
        string memory path = string(abi.encodePacked("./data/ecdsa/signDatas", len.toString(), ".json"));

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
                    testContract.checkMint(result.index, result.allowedAmount, result.allowedAmount, result.signature);
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
        string memory path = string(abi.encodePacked("./data/ecdsa/settings", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // decode
        bytes memory abiEncodedData = vm.parseJson(readJson);
        SettingsJson memory settings = abi.decode(abiEncodedData, (SettingsJson));

        // setting bitChecker
        bitChecker = settings.bitChecker;
        address signerAddress = settings.signerAddress;

        testContract.setCheckers(bitChecker);
        testContract.setCheckAddress(signerAddress);
    }

    function helperCreateData(uint256 len) public returns (address signerAddress) {
        string memory path = string(abi.encodePacked("./data/ecdsa/settings", len.toString(), ".json"));

        // read to file
        string memory readJson = vm.readFile(path);

        // decode
        bytes memory abiEncodedData = vm.parseJson(readJson);
        SettingsJson memory settings = abi.decode(abiEncodedData, (SettingsJson));

        bitChecker = settings.bitChecker;
        signerAddress = settings.signerAddress;

        return signerAddress;
    }
}
