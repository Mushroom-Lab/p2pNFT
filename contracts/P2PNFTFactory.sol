pragma solidity =0.8.11;

import '../interfaces/IP2PNFTFactory.sol';
import '../interfaces/IP2PNFT.sol';
import './P2PNFT.sol';


contract P2PNFTFactory is IP2PNFTFactory {
    // hash of description (uid) to contract address 
    mapping(bytes32 => address) public getNFT;
    address[] public allNFTs;

    event NFTCreated(bytes32 indexed uid, address nftAddress, uint id);
    function allNFTsLength() external view returns (uint) {
        return allNFTs.length;
    }

    function createNFT(string memory description) external returns (address p2pNFT) {
        bytes32 uid = keccak256(abi.encode(description));
        require(getNFT[uid] == address(0), 'NFT_EXISTS');
        bytes memory bytecode = type(P2PNFT).creationCode;
        bytes32 salt = uid;
        assembly {
            p2pNFT := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IP2PNFT(p2pNFT).initialize(description);
        getNFT[uid] = p2pNFT;
        allNFTs.push(p2pNFT);
        emit NFTCreated(uid, p2pNFT, allNFTs.length);
    }

}