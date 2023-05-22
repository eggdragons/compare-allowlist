// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract GasReport is Test {
    using Strings for uint256;

    // uint256 sampleNumber = 128;
    string key = "Len";
    uint256 sampleNumber = vm.envOr(key, uint256(128));

    // use gasReport
    uint256 startGas;
    uint256 gasUsed;
    uint256 gasUsedForSettings;
    uint256 gasUsedForFunctions;
    uint256 totalAmounts;

    function createGasReport(
        string memory _fileName,
        uint256 _len,
        uint256 _gasUsedForSettings,
        uint256 _gasUsedForFunctions,
        uint256 _totalAmounts
    ) public {
        string memory path = string(abi.encodePacked("./data/result/", _fileName, _len.toString(), ".json"));

        // create writeJson
        string memory obj1 = "key";
        string memory writeJson = vm.serializeUint(obj1, "gasUsedForSettings", _gasUsedForSettings);

        writeJson = vm.serializeUint(obj1, "gasUsedForFunctions", _gasUsedForFunctions);

        writeJson = vm.serializeUint(obj1, "totalAmounts", _totalAmounts);

        // write to file
        vm.writeJson(writeJson, path);
    }
}
