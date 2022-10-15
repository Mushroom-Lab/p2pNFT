pragma solidity ^0.8.4;

interface IP2PNFTWallet {
    function owner() external returns(address);
    function admin() external returns(address);
}