# to be used in brownie console
from brownie import *
import os
from dotenv import load_dotenv

import eth_abi

from web3.auto import w3
from web3 import Web3
from eth_account.messages import encode_defunct

load_dotenv()

address = os.getenv('p2pNFT_opt')
ac1_private_key = os.getenv("AC1")
ac2_private_key = os.getenv("AC2")
ac3_private_key = os.getenv("AC3")
ac1 = accounts.add(private_key=ac1_private_key)
ac2 = accounts.add(private_key=ac2_private_key)
# countrol
ac3 = accounts.add(private_key=ac3_private_key)

# test message
message = "bafyreicztgskd5wt6ssc2mkpc4cdtulr44bdgzndvvhryclpnovw2yw3wm"
# convert this message to 32bytes
rawMessageHash = Web3.keccak(text=message)

abiEncoded = eth_abi.encode_abi(['address[]', 'bytes32'], [[ac1.address,ac2.address], rawMessageHash])
hashed = Web3.solidityKeccak(['bytes'], ['0x' + abiEncoded.hex()]).hex()

#0x8f5cfeee1e97fda7ffd139aaef1e16cb26e18ceeae10087faa0717e2f215b5b7?
message = encode_defunct(hexstr=hashed)
ac1_signed = w3.eth.account.sign_message(message, private_key=ac1_private_key)
ac2_signed = w3.eth.account.sign_message(message, private_key=ac2_private_key)

# check addresses
print(w3.eth.account.recover_message(message, signature=ac1_signed.signature))
print(w3.eth.account.recover_message(message, signature=ac2_signed.signature))

p = P2PNFT.at(address)
#good example
tx = p.initilizeNFT(ac1_signed.signature + ac2_signed.signature, rawMessageHash, [ac1.address ,ac2.address], {'from': ac2})
print(tx.events)
print(p.p2pwhitelist(0,ac1))
print(p.p2pwhitelist(0, ac2))
# pass
p.mint(0, ac1, {'from': ac2})
p.mint(0, ac2, {'from': ac2})
print(p.balanceOf(ac1,0))

# revert not whitelisted
p.mint(0, ac3, {'from': admin})
# already minted
p.mint(0, ac1, {'from': admin})

# soulbound
p.safeTransferFrom(ac1, ac3, 0, 1, "", {'from' : ac1})
