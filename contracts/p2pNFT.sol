// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../interfaces/IP2PNFT.sol";


error WrongResolvedAddress(address resolved, address targeted);
error HashAlreadyMinted(bytes32 _rawMessageHash, address signer);

contract P2PNFT is IP2PNFT, ERC1155 {
    using Counters
    for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address public factory;
    // unique identifier from dscription to identify eacch P2PNFT in factory.
    string public constant name = "P2PNFT";
    bytes32 public uid;
    string public description;

    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address delegatee,uint256 nonce)");
    bytes32 public constant PERMIT_TYPEHASH = 0xb386f97c45a5e4526fa8514e4421b36a232e2dfcf252547ffc9d886063bd3842;
    // a mapping that map each token => address => canMint
    mapping (uint256 => mapping (address => bool)) public p2pwhitelist;
    // a mapping that map each Hash to address => is consumed to avoid replay
    mapping (bytes32 => mapping (address => bool)) public isHashUsed;
    // delegationMap, map owner to their delegatee.
    mapping (address => address) public delegation;
    // nonces to avoid replay on permit
    mapping(address => uint) public nonces;
    // Mapping from token ID to the ipfs cid
    mapping(uint256 => string) public tokenToCid;

    event TokenInitializedAddress(uint256 indexed token_Id, address _address);
    event TokenInitialized(uint256 indexed token_Id, string tokenCid);
    event NewDelegation(address owner, address delegatee);

    constructor() ERC1155("") {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        factory = msg.sender;
    }

    function initialize(string memory _description) external {
        require(msg.sender == factory, 'FORBIDDEN'); // sufficient check
        description = _description;
        uid = keccak256(abi.encode(_description));
    }

    // anyone can mint anything as long as they have all the signature from particpiant
    // signature => ETHSign(_rawMessageHash) = > hash(addresses + uid + tokenCid)
    function initilizeNFT(bytes memory _signatures, address[] memory owners, string memory tokenCid) external {
        bytes32 messageHash = getMessageHash(owners, tokenCid);
        // number of signatures has to match number of participants
        uint256 _noParticipants = owners.length;
        //require(_signatures.length == _noParticipants * 65, "inadequate signatures");
        uint256 tokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < _noParticipants; i++) {
            address p = recover(_signatures, i,  owners, tokenCid);

            address owner = owners[i];
            address delegatee = delegation[owner];
            
            // if there is no delegatee, default to the owner.
            if (delegatee == address(0)) {
                delegatee = owner;
            }
            // if the resolved address from signature does not match the delegatee
            if (p != delegatee) {
                 revert WrongResolvedAddress(p, delegatee);
            }
            // if the owner has already minted this hash
            if (isHashUsed[messageHash][owner]) {
                revert HashAlreadyMinted(messageHash, owner);
            }
            isHashUsed[messageHash][owner] = true;
            p2pwhitelist[tokenId][owner] = true;
            emit TokenInitializedAddress(tokenId, owner);
        }
        _setTokenCid(tokenId, tokenCid);
        _tokenIdCounter.increment();
        emit TokenInitialized(tokenId, tokenCid);
    }

    function mint(uint256 tokenId, address to) external {
        require(p2pwhitelist[tokenId][to], "not whitelist");
        require(balanceOf(to,tokenId) == 0, "already minted");
        super._mint(to, tokenId, 1, "");
    }

    // allow change of this mapping using off-chain signature similar to EIP2612
    function permit(address owner, address delegatee, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, delegatee, nonces[owner]++))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNATURE");
        _setDelegatee(owner, delegatee);
    } 

    function setDelegatee(address delegatee) external returns(bool) {
        _setDelegatee(msg.sender, delegatee);
        return true;
    }

    function _setDelegatee(address owner, address delegatee) private {
        delegation[owner] = delegatee;
        emit NewDelegation(owner, delegatee);
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

    // recall signature => ETHSign(_rawMessageHash) = > hash(addresses + uid + tokenCid)
    function recover(bytes memory _signatures,  uint256 i, address[] memory owners, string memory tokenCid) public view returns (address) {
        bytes32 _ethSignedMessageHash = getMessageHash(owners, tokenCid);
        (uint8 v, bytes32 r, bytes32 s) = signaturesSplit(_signatures, i);
        address p = ecrecover(_ethSignedMessageHash, v, r, s);
        return p;
    }

    // real message never live on chain due to its size constraint
    function getMessageHash(address[] memory addresses, string memory tokenCid) public view returns (bytes32) {
        bytes32 rawMessageHash = keccak256(abi.encode(addresses, uid, tokenCid));
        return getEthSignedMessageHash(rawMessageHash);
    }
    function getEthSignedMessageHash(bytes32 _rawMessageHash)
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
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _rawMessageHash)
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