// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;
import "../interfaces/IP2PNFTWallet.sol";


contract P2PNFTWallet {

    // owner own this wallet, there is no way to change it except 1-time migration in custodian mode
    address public owner;
    // custodian if needed, or not set to false
    bool public isCustodian;
    // operator can call iinitializeNFT on behalf of owner;
    address public admin;

    event ownerUpdated(address _newOwner);
    event adminUpdated(address _newAdmin);
    constructor(address _owner, address _admin, bool _isCustodian) {
        owner = _owner;
        admin = _admin;
        isCustodian = _isCustodian;
        emit ownerUpdated(_owner);
        emit adminUpdated(_admin);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "onlyOwner");
        _;
    }

    modifier onlyAdminOrOwner {
        require(admin == msg.sender || owner == msg.sender, "only admin or owner");
        _;
    }

    // modifier for migration
    modifier CustodyMode {
        require(isCustodian);
        _;
    }
    
    // 1-time reset owner 
    function migrate(address _newOwner) external onlyOwner CustodyMode {
        isCustodian = false;
        owner = _newOwner;
        emit ownerUpdated(_newOwner);
    }
    // setter
    function setAdmin(address _newAdmin) external onlyOwner {
        admin = _newAdmin;
        emit adminUpdated(_newAdmin);
    }
}