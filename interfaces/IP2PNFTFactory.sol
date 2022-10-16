pragma solidity =0.8.11;

interface IP2PNFTFactory {
    function allNFTsLength() external view returns (uint);
    function createNFT(string calldata) external returns (address);
}