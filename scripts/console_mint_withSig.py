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
p2pnft = os.getenv('p2pNFT_mumbai')
ac2_private_key = os.getenv("AC2")
ac2 = accounts.add(private_key=ac2_private_key)
ac1_private_key = os.getenv("AC1")
ac1 = accounts.add(private_key=ac1_private_key)

# test message
#message = "bafyreigvnhtpiuybtomyskz5biswa4w6zfizsrbvyzkklzn557d2dmo2e4"
cid = "bafyreigvnhtpiuybtomyskz5biswa4w6zfizsrbvyzkklzn557d2dmo2e4"
# team hash : bafyreihkxnh7jnxmbzfzkuk2pcz7fncli5tkqjmtjttqzqbxs6rcsvcmpy
# ac1 = "0xa83CEfd794f060C5AD9Ad8F473d209a26e8EEC2d"
# convert this message to 32bytes
# rawMessageHash = Web3.keccak(text=message)

abiEncoded = eth_abi.encode_abi(['address[]', 'bytes32'], [[ac1,ac2.address], rawMessageHash])
# this is what we have to sign
hashed = Web3.solidityKeccak(['bytes'], ['0x' + abiEncoded.hex()]).hex()

#0x8f5cfeee1e97fda7ffd139aaef1e16cb26e18ceeae10087faa0717e2f215b5b7?
message = encode_defunct(hexstr=hashed)

signature = "0x0423dc8fdce875ffb09cb29a4938a4e1f363af90fa23aedb0fbb26ded3857c8b7a43a680bfedf84ee30fbe2196734669c5b22e364d34573bb8ac2f58745c52f41c"

ac1_signed = signature
ac2_signed = w3.eth.account.sign_message(message, private_key=ac2_private_key)

# check addresses
print(w3.eth.account.recover_message(message, signature=ac1_signed))
print(w3.eth.account.recover_message(message, signature=ac2_signed.signature))

p = P2PNFT.at(p2pnft)
#good example
tx = p.initilizeNFT(HexBytes(ac1_signed) + ac2_signed.signature, rawMessageHash, [ac1 ,ac2.address],cid, {'from': ac2})
print(tx.events)
print(p.p2pwhitelist(4,ac1))
print(p.p2pwhitelist(4, ac2))
# pass
tokenid = 4
p.mint(tokenid, ac1, {'from': ac2})
p.mint(tokenid, ac2, {'from': ac2})
print(p.balanceOf(ac1,0))

