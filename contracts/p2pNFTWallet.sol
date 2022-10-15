// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IP2PNFTWallet.sol";


error WrongAdminAddress(address operator, address walletAdmin);
error HashAlreadyMinted(bytes32 _rawMessageHash, address signer);

contract P2PNFTWallet is ERC1155 {
    using Counters
    for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // owner own this wallet, there is no way to change it except 1-time migration in custodian mode
    address public owner;
    // custodian if needed, or not set to false
    bool public isCustodian;
    // operator can call iinitializeNFT on behalf of owner;
    address public admin;
    // a mapping that map each token => address => canMint
    mapping (uint256 => mapping (address => bool)) public p2pwhitelist;
    // a mapping that map each Hash to address => is consumed
    mapping (bytes32 => mapping (address => bool)) public isHashUsed;
    // Mapping from token ID to the ipfs cid
    mapping(uint256 => string) public tokenToCid;

    event TokenInitializedAddress(uint256 indexed token_Id, address _address);
    event TokenInitialized(uint256 indexed token_Id, bytes32 _rawMessageHash);

    constructor(address _owner, address _admin, bool _isCustodian) ERC1155("") {
        owner = _owner;
        admin = _admin;
        isCustodian = _isCustodian;
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
    }
    // setter
    function setAdmin(address _newAdmin) external onlyOwner {
        admin = _newAdmin;
    }
    
    // verify signature from operator
    // update whitelist for the OWNER from which the operator represent
    // to map operator to its OWNER we also need their wallet address
    function initilizeNFTforWallet(bytes memory _signatures, bytes32 _rawMessageHash, address[] memory wallets, string memory tokenCid) onlyAdminOrOwner external {
        uint256 _noParticipants = admins.length;
        // number of signatures has to match number of participants
        require(_signatures.length == _noParticipants * 65, "inadequate signatures");
        uint256 tokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < _noParticipants; i++) {
            address p = recover(_signatures, i,  admins, _rawMessageHash);
            // if the recovered address is not the admin
            address admin = IP2PNFTWallet(wallets[i]).admin();
            if (p != admin) {
                 revert WrongAdminAddress(p, admin);
            }
            // if the wallet already mint this hash
            if (isHashUsed[_rawMessageHash][wallets[i]]) {
                revert HashAlreadyMinted(_rawMessageHash,wallets[i]);
            }
            isHashUsed[_rawMessageHash][wallets[i]] = true;
            p2pwhitelist[tokenId][wallets[i]] = true;
            emit TokenInitializedAddress(tokenId, wallets[i]);
        }
        _setTokenCid(tokenId, tokenCid);
        _tokenIdCounter.increment();
        emit TokenInitialized(tokenId, _rawMessageHash);
    }

    function mint(uint256 tokenId, address to) external {
        require(p2pwhitelist[tokenId][to], "not whitelist");
        require(balanceOf(to,tokenId) == 0, "already minted");
        super._mint(to, tokenId, 1, "");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < _tokenIdCounter.current(), "tokenId does not exist");
        return string(
            abi.encodePacked(
                "ipfs://",
                tokenToCid[tokenId],
                "/metadata.json"
            )
        );
    }

    function _setTokenCid(uint256 tokenId, string memory tokenCid) private {
         tokenToCid[tokenId] = tokenCid; 
    } 

    // verify
    function recover(bytes memory _signatures,  uint256 i, address[] memory admins, bytes32 _rawMessageHash) public pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = signaturesSplit(_signatures, i);
            bytes32 _messageHash = getMessageHash(admins, _rawMessageHash);
            bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);
            address p = ecrecover(_ethSignedMessageHash, v, r, s);
            return p;
    }
    // real message never live on chain due to its size constraint
    function getMessageHash(address[] memory addresses, bytes32 _rawMessageHash) public pure returns (bytes32) {
        return keccak256(abi.encode(addresses, _rawMessageHash));
    }
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
    function signaturesSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    // soulbound features
    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155) {
        super._afterTokenTransfer(operator, address(0), to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155) {
        require(from == address(0), "Err: token is SOUL BOUND");
        super._beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
    }
}