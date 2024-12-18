// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IEAS, Attestation, AttestationRequest, AttestationRequestData } from "eas-contracts/IEAS.sol";
import { SchemaResolver } from "eas-contracts/resolver/SchemaResolver.sol";
import { IHypercertToken } from "./IHypercertToken.sol";

error CALLER_IS_NOT_ATTESTER(address attester);

/// @title Resolver
contract Resolver is SchemaResolver {
    constructor(IEAS eas) SchemaResolver(eas) { }

    function onAttest(Attestation calldata attestation, uint256 /*value*/ ) internal view override returns (bool) {
        // decode the data from the attestation
        (, address contractAddress, uint256 tokenId,,,) =
            abi.decode(attestation.data, (uint256, address, uint256, string, string, string[]));

        // check if the attester is the creator of the token
        address creator = IHypercertToken(contractAddress).owner(tokenId);
        if (creator != attestation.attester) {
            revert CALLER_IS_NOT_ATTESTER(attestation.attester);
        }
    }

    function onRevoke(Attestation calldata, /*attestation*/ uint256 /*value*/ ) internal pure override returns (bool) {
        return true;
    }
}
