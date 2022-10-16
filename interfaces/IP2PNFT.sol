pragma solidity =0.8.11;
interface IP2PNFT {

    function description() external returns (string memory);
    function uid() external returns (bytes32);
    function initialize(string memory) external;
    function initilizeNFT(bytes memory, address[] memory, string memory) external;
    function mint(uint256, address) external;
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address) external view returns (uint);
    function permit(address, address, uint8 v, bytes32 r, bytes32 s) external;

}