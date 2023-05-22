// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "helper/TestHelpers.t.sol";
import "contracts/NonCheckSign.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// forge test --match-contract NonCheckSignTest --match-test testGasReportCheckMintNormal -vvvvv --gas-report

contract NonCheckSignTest is TestHelpers {
    using stdJson for string;
    using Strings for uint256;

    // setting
    uint256 _testLen = sampleNumber;

    // attenstion name sort ASC
    struct Json {
        uint256 allowedAmount;
        address user;
    }

    NonCheckSign public testContract;

    function setUp() public onlyOwner {
        testContract = new NonCheckSign();
    }

    /* /////////////////////////////////////////////////////////////////////////////
    Non Allowlist
    ///////////////////////////////////////////////////////////////////////////// */

    function testCheckMintNormal() public {
        // test setting
        uint256 len = _testLen;

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
                testContract.nonCheckMint(result.allowedAmount);
                vm.stopPrank();
                ++i;
            }
        }
    }

    function testGasReportCheckMintNormal() public {
        // test setting
        uint256 len = _testLen;
        gasUsedForSettings = 0;

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

                // check gas start
                startGas = gasleft();

                testContract.nonCheckMint(result.allowedAmount);

                // check gas stop
                gasUsed = startGas - gasleft();
                gasUsedForFunctions = gasUsedForFunctions + gasUsed;

                totalAmounts = totalAmounts + result.allowedAmount;

                vm.stopPrank();
                ++i;
            }
        }
        createGasReport("NonCheckSign", len, gasUsedForSettings, gasUsedForFunctions, totalAmounts);
    }
}
