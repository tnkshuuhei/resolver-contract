// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IEAS, Attestation } from "eas-contracts/IEAS.sol";
import { SchemaResolver } from "eas-contracts/resolver/SchemaResolver.sol";
import { IHypercertToken } from "./IHypercertToken.sol";

/// @title Resolver
contract Resolver is SchemaResolver {
    IHypercertToken public hypercert;

    /// @notice Mapping of token IDs to approved attesters
    mapping(uint256 => address[]) public approvedAttesters;

    /// @notice recvert if the caller is not the attester
    error CALLER_IS_NOT_ATTESTER(address attester);

    /// @notice revert if the caller is not the creator
    error CALLER_IS_NOT_CREATOR(address creator);

    error INVALID_ATTESTER(address attester);

    /// @notice revert if the token address is invalid
    error INVALID_TOKEN_ADDRESS(address tokenAddress);

    /// @notice Event emitted when an attester is added to a token
    event AttesterAdded(uint256 tokenId, address attester);

    /// @notice Event emitted when an attester is revoked from a token
    event AttesterRevoked(uint256 tokenId, address attester);

    constructor(IEAS eas, address _hypercert) SchemaResolver(eas) {
        hypercert = IHypercertToken(_hypercert);
    }

    function addAttester(uint256 tokenId, address attester) external {
        if (hypercert.owner(tokenId) != attester) {
            revert CALLER_IS_NOT_CREATOR(attester);
        }
        approvedAttesters[tokenId].push(attester);
        emit AttesterAdded(tokenId, attester);
    }

    function revokeAttester(uint256 tokenId, address attester) external {
        if (hypercert.owner(tokenId) != msg.sender) {
            revert CALLER_IS_NOT_CREATOR(msg.sender);
        }

        if (isApprovedAttester(tokenId, attester) == false) {
            revert INVALID_ATTESTER(attester);
        }

        address[] storage attesters = approvedAttesters[tokenId];

        for (uint256 i = 0; i < attesters.length; i++) {
            if (attesters[i] == attester) {
                attesters[i] = attesters[attesters.length - 1];
                attesters.pop();
                emit AttesterRevoked(tokenId, attester);
                return;
            }
        }
    }

    function isApprovedAttester(uint256 tokenId, address attester) public view returns (bool) {
        address[] memory attesters = approvedAttesters[tokenId];

        for (uint256 i = 0; i < attesters.length; i++) {
            if (attesters[i] == attester) {
                return true;
            }
        }

        return false;
    }

    function onAttest(Attestation calldata attestation, uint256 /*value*/ ) internal view override returns (bool) {
        // decode the data from the attestation
        (, address contractAddress, uint256 tokenId,,,) =
            abi.decode(attestation.data, (uint256, address, uint256, string, string, string[]));

        // check if the token address is the same as the hypercert address
        if (contractAddress != address(hypercert)) {
            revert INVALID_TOKEN_ADDRESS(contractAddress);
        }

        // check if the attester is the creator of the token
        address creator = hypercert.owner(tokenId);
        if (creator == attestation.attester || isApprovedAttester(tokenId, attestation.attester)) {
            return true;
        } else {
            revert CALLER_IS_NOT_ATTESTER(attestation.attester);
        }
    }

    function onRevoke(Attestation calldata, /*attestation*/ uint256 /*value*/ ) internal pure override returns (bool) {
        return true;
    }
}
