# to be used in brownie console
from brownie import *
import os
from dotenv import load_dotenv

import eth_abi
from hexbytes import HexBytes
from web3.auto import w3
from web3 import Web3
from eth_account.messages import encode_defunct

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

tx = p.initilizeNFT(ac1_signed.signature + ac2_signed.signature, [ac1.address,ac2.address], cid, {'from': ac2, 'gas_limit': "2321688", "allow_revert":True})