// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// Made with Love by Dennison Bertram @Tally.xyz
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract P2PNFT is ERC721, Ownable, EIP712, ERC721Votes {
    using Counters
    for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // a mapping that map each token => address => canMint
    mapping (uint256 => mapping (address => bool)) public p2pwhitelist;

    event TokenInitialized(uint256 indexed token_Id, bytes32 message, bytes _signatures);

    constructor() ERC721("P2PNFT", "P2P") EIP712("P2PNFT", "1") {}

    function _baseURI() internal pure override returns(string memory) {
        return "<https://www.myapp.com/>";
    }

    // anyone can mint anything as long as they have all the signature from particpiant

    function initilizeNFT(bytes memory _signatures, bytes32 _messageHash, uint256 _noParticipants) external {
        // number of signatures has to match number of participants
        require(_signatures.length >= _noParticipants * 65, "inadequate signatures");
        uint256 tokenId = _tokenIdCounter.current();
        for (uint256 i = 0; i < _noParticipants; i++) {
            (uint8 v, bytes32 r, bytes32 s) = signaturesSplit(_signatures, i);
            bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);
            require(_messageHash == _ethSignedMessageHash, "signed message is different from the given message");
            address p = ecrecover(_ethSignedMessageHash, v, r, s);
            p2pwhitelist[tokenId][p] = true;
        }
        emit TokenInitialized(tokenId, _messageHash, _signatures);
        _tokenIdCounter.increment();
    }

    function mint(uint256 tokenId, address to) external {
        require(p2pwhitelist[tokenId][to], "not whitelist");
        _mint(to, tokenId);
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

    function verify(
        address _signer,
        bytes32 messageHash,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
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
    function _afterTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721) {
        require(from == address(0), "Err: token is SOUL BOUND");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}