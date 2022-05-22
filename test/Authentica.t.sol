// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;


import "forge-std/Test.sol";
import {Authentica} from "../src/Authentica.sol";

contract AuthenticaTest is Authentica, Test {
    Authentica authentica;

    function setUp() public {
        authentica = new Authentica();
    }
}