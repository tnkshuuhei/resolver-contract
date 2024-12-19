// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { console } from "forge-std/console.sol";
import { BaseScript } from "./Base.s.sol";

import { ISchemaRegistry } from "eas-contracts/ISchemaRegistry.sol";
import { ISchemaResolver } from "eas-contracts/resolver/ISchemaResolver.sol";

contract CreateSchema is BaseScript {
    string constant SCHEMA =
        "uint256 chain_id,address contract_address,uint256 token_id,string title,string description,string[] sources";
    address resolver = address(0);

    function run() public broadcast {
        bytes32 schemaUID = ISchemaRegistry(0x0a7E2Ff54e76B8E6659aedc9103FB21c038050D0).register(
            SCHEMA, ISchemaResolver(resolver), false
        );
        console.log("Schema UID: ");
        console.logBytes32(schemaUID);
    }
}
