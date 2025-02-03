// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "root/lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "root/lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "root/lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "root/lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract TippingProxy{
    //admin role

    //implementation address
    constructor(){}

    modifier onlyAdmin(){}

    function UpgradeTo(){}
    
    function implementationVersion(){}
    
    function _setAdmin(){}

    function _getAdmin(){}

    function _setImplementation(){}

    function _getImplementation(){}

    recieve()

    fallback(){}
}


contract TippingImplementationV1{
    constructor(){}

    function registerCreator(){}

    function sendTip(){}

    function withdrawTips(){}

    function getCreatorDetials(){}
}