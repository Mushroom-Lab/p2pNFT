// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


error WrongResolvedAddress(address resolved, address targeted);
error HashAlreadyMinted(bytes32 _rawMessageHash, address signer);

contract P2PNFT is ERC1155 {
    using Counters
    for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // a mapping that map each token => address => canMint
    mapping (uint256 => mapping (address => bool)) public p2pwhitelist;
    // a mapping that map each Hash to address => is consumed
    mapping (bytes32 => mapping (address => bool)) public isHashUsed;
    // Mapping from token ID to the ipfs cid
    mapping(uint256 => string) public tokenToCid;

    event TokenInitializedAddress(uint256 indexed token_Id, address _address);
    event TokenInitialized(uint256 indexed token_Id, bytes32 _rawMessageHash);

    constructor() ERC1155("") {}

    // anyone can mint anything as long as they have all the signature from particpiant
    function initilizeNFT(bytes memory _signatures, bytes32 _rawMessageHash, address[] memory addresses, string memory tokenCid) external {
        // number of signatures has to match number of participants
        uint256 _noParticipants = addresses.length;
        //require(_signatures.length == _noParticipants * 65, "inadequate signatures");
        uint256 tokenId = _tokenIdCounter.current();
        _setTokenCid(tokenId, tokenCid);
        for (uint256 i = 0; i < _noParticipants; i++) {
            (uint8 v, bytes32 r, bytes32 s) = signaturesSplit(_signatures, i);
            bytes32 _messageHash = getMessageHash(addresses, _rawMessageHash);
            bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);
            address p = ecrecover(_ethSignedMessageHash, v, r, s);
            if (p != addresses[i]) {
                 revert WrongResolvedAddress(p, addresses[i]);
            }
            if (isHashUsed[_rawMessageHash][p]) {
                revert HashAlreadyMinted(_rawMessageHash,p);
            }
            isHashUsed[_rawMessageHash][p] = true;
            p2pwhitelist[tokenId][p] = true;
            emit TokenInitializedAddress(tokenId, p);
        }
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
                "metadata.json"
            )
        );
    }

    function _setTokenCid(uint256 tokenId, string memory tokenCid) private {
         tokenToCid[tokenId] = tokenCid; 
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