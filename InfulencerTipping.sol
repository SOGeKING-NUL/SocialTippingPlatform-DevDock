// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "root/lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "root/lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import "root/lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "root/lib/openzeppelin-contracts/contracts/utils/Address.sol";

contract TippingProxy{

    bytes32 private constant ADMIN_SLOT= 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;    
    bytes32 private constant IMPLEMENTATION_SLOT= 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(){
        _setAdmin(msg.sender);
    }

    modifier onlyAdmin(){
        require(msg.sender == _getAdmin(), "you are not the admin");
        _;
    }

    function updateAdmin(address newAdmin) external onlyAdmin{
        require(newAdmin != address(0), "invalid admin address");
        _setAdmin(newAdmin);
    }

    function UpgradeTo(address newImplementation) external onlyAdmin{
        require(newImplementation != address(0), "not a valid contract address");
        require(newImplementation.code.length > 0, "Implementation contract doesnt exist");
        _setImplementation(newImplementation);

    }
    
    function Implementation() external view onlyAdmin returns(address){
        return _getImplementation();
    }

    receive() external payable {}

    fallback() external payable{
        address implementation= _getImplementation();
        require(implementation != address(0), "no implementation set" );
        (bool success,) = implementation.delegatecall(msg.data);
        require(success, "delegation failed");
    }

    function _setAdmin(address admin) private{
        assembly{
            sstore(ADMIN_SLOT, admin);
        }
    }
    
    function _getAdmin() internal view returns(address admin){
        assembly{
            admin := sload(ADMIN_SLOT);
        }
    }

    function _setImplementation(address newImplementation) private{
        assembly{
            sstore(IMPLEMENTATION_SLOT, newImplementation);
        }
    }

    function _getImplementation() internal view returns(address implementation){
        assembly{
            implementation := sload(IMPLEMENTATION_SLOT);
        }
    }
}


contract TippingImplementationV1{
    constructor(){}

    function registerCreator(){}

    function sendTip(){}

    function withdrawTips(){}

    function getCreatorDetials(){}
}