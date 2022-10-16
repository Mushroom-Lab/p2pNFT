# to be used in brownie console
from brownie import *
import os
from dotenv import load_dotenv

import eth_abi
from hexbytes import HexBytes
from web3.auto import w3
from web3 import Web3
from eth_account.messages import encode_defunct, encode_structured_data

load_dotenv()

#p2pnft = os.getenv('p2pNFT_mumbai')
#p2pnftFactory = os.getenv('p2pNFT_mumbai')

#admin_private_key = os.getenv("PRIVATE_KEY")
#admin = accounts.add(private_key=admin_private_key)
admin = accounts[0]
tx = P2PNFTFactory.deploy({'from': admin, "gas_price": "40 gwei"})
p2pnftFactory = tx.address
# deploy NFT from factory
description = "FwB"
tx=P2PNFTFactory.at(p2pnftFactory).createNFT(description, {'from': admin, "gas_price": "40 gwei"})

ac2_private_key = os.getenv("AC2")
ac2 = accounts.add(private_key=ac2_private_key)
ac1_private_key = os.getenv("AC1")
ac1 = accounts.add(private_key=ac1_private_key)
# mint a NFT
cid = "bafyreigvnhtpiuybtomyskz5biswa4w6zfizsrbvyzkklzn557d2dmo2e4"
uid = tx.events['NFTCreated']['uid']
p2pnft = tx.events['NFTCreated']['nftAddress']
abiEncoded = eth_abi.encode_abi(['address[]', 'bytes32', 'string'], [[ac1.address,ac2.address], uid, cid])
hashed = Web3.solidityKeccak(['bytes'], ['0x' + abiEncoded.hex()]).hex()
message = encode_defunct(hexstr=hashed)

ac1_signed = w3.eth.account.sign_message(message, private_key=ac1_private_key)
ac2_signed = w3.eth.account.sign_message(message, private_key=ac2_private_key)

print(w3.eth.account.recover_message(message, signature=ac1_signed.signature))
print(w3.eth.account.recover_message(message, signature=ac2_signed.signature))

p = P2PNFT.at(p2pnft)

tx = p.initilizeNFT(ac1_signed.signature + ac2_signed.signature, [ac1.address,ac2.address], cid, {'from': ac2})

## create a signature to call permit

def sign_token_permit(name, address, chain_id, owner, delegatee, nonce):
    data = {
        "types": {
            "EIP712Domain": [
                {"name": "name", "type": "string"},
                {"name": "version", "type": "string"},
                {"name": "chainId", "type": "uint256"},
                {"name": "verifyingContract", "type": "address"},
            ],
            "Permit": [
                {"name": "owner", "type": "address"},
                {"name": "delegatee", "type": "address"},
                {"name": "nonce", "type": "uint256"},
            ],
        },
        "domain": {
            "name": name,
            "version": "1",
            "chainId": chain_id,
            "verifyingContract": address,
        },
        "primaryType": "Permit",
        "message": {
            "owner": owner,
            "delegatee": delegatee,
            "nonce": nonce
        },
    }
    permit = encode_structured_data(data)
    return permit

owner = ac1.address

name = p.name()
nonce = p.nonces(ac1.address)
# abiEncoded = eth_abi.encode_abi(['bytes32', 'address', 'address', 'uint256'], [PERMIT_TYPEHASH, ac1.address, ac2.address, nonce])
# hashed = Web3.solidityKeccak(['bytes'], ['0x' + abiEncoded.hex()]).hex()

# reabiEncoded = eth_abi.packed.encode_abi_packed(['string', 'bytes32', 'bytes32'], ["\x19\x01", DOMAIN_SEPARATOR, HexBytes(hashed)])
# rehashed =  Web3.solidityKeccak(['bytes'], ['0x' + reabiEncoded.hex()]).hex()
message = sign_token_permit(name, p.address, 1, ac1.address, ac2.address, nonce)
ac1_signed = w3.eth.account.sign_message(message, private_key=ac1_private_key)
print(w3.eth.account.recover_message(message, signature=ac1_signed.signature))

tx = p.permit(ac1.address, ac2.address, ac1_signed.v, ac1_signed.r, ac1_signed.s, {'from': ac2})
print(tx.events)