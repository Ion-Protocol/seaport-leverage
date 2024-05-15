// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { BaseScript } from "./Base.s.sol";

import { IIonPool } from "../src/interfaces/IIonPool.sol";
import { IGemJoin } from "../src/interfaces/IGemJoin.sol";
import { SeaportDeleverage } from "../src/SeaportDeleverage.sol";

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { CREATEX } from "@ionprotocol/src/Constants.sol";

import { stdJson as StdJson } from "forge-std/StdJson.sol";

contract DeploySeaportDeleverageScript is BaseScript {
    using StdJson for string;
    using SafeCast for uint256;

    string configPath = "./deployment-config/DeploySeaportDeleverage.json";
    string config = vm.readFile(configPath);

    IIonPool ionPool = IIonPool(config.readAddress(".ionPool"));
    IGemJoin gemJoin = IGemJoin(config.readAddress(".gemJoin"));
    uint8 ilkIndex = config.readUint(".ilkIndex").toUint8();
    bytes32 salt = config.readBytes32(".salt");

    function run() public broadcast returns (SeaportDeleverage seaportDeleverage) {
        require(address(ionPool).code.length > 0, "ionPool address must have code");
        require(address(gemJoin).code.length > 0, "gemJoin address must have code");
        require(ionPool.hasRole(ionPool.GEM_JOIN_ROLE(), address(gemJoin)), "gemJoin must have GEM_JOIN_ROLE");
        require(gemJoin.GEM() == ionPool.underlying(), "GEM must be underlying");
        require(gemJoin.POOL() == address(ionPool), "POOL must be ionPool");
        require(gemJoin.ILK_INDEX() == ilkIndex, "ILK_INDEX must match");

        bytes memory initCode = type(SeaportDeleverage).creationCode;

        seaportDeleverage = SeaportDeleverage(
            CREATEX.deployCreate3(salt, abi.encodePacked(initCode, abi.encode(ionPool, gemJoin, ilkIndex)))
        );

        require(address(seaportDeleverage.POOL()) == address(ionPool), "POOL must be ionPool");
        require(address(seaportDeleverage.JOIN()) == address(gemJoin), "JOIN must be gemJoin");
    }
}
