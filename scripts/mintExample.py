# to be used in brownie console
from brownie import *
import os
from dotenv import load_dotenv

import eth_abi

from web3.auto import w3
from web3 import Web3
from eth_account.messages import encode_defunct

load_dotenv()

admin = accounts[0]
ac1_private_key = os.getenv("AC1")
ac2_private_key = os.getenv("AC2")
ac1 = accounts.add(private_key=ac1_private_key)
ac2 = accounts.add(private_key=ac2_private_key)
# countrol
ac3 = accounts[1]


#deployment
P2PNFT.deploy({'from': admin})

# test message
message = "ac1 love ac2"
# convert this message to 32bytes
rawMessageHash = Web3.keccak(text=message)

noOfParticipant = 2

abiEncoded = eth_abi.encode_abi(['uint256', 'bytes32'], [noOfParticipant, rawMessageHash])
hashed = Web3.solidityKeccak(['bytes'], ['0x' + abiEncoded.hex()]).hex()

message = encode_defunct(hexstr=hashed)
ac1_signed = w3.eth.account.sign_message(message, private_key=ac1_private_key)
ac2_signed = w3.eth.account.sign_message(message, private_key=ac2_private_key)

# check addresses
#print(w3.eth.account.recover_message(message, signature=ac1_signed.signature))
#print(w3.eth.account.recover_message(message, signature=ac2_signed.signature))

#good example
tx = P2PNFT[0].initilizeNFT(ac1_signed.signature + ac2_signed.signature, rawMessageHash, noOfParticipant, [ac1.address ,ac2.address], {'from': admin})
print(tx.events)
print(P2PNFT[0].p2pwhitelist(0,ac1))
print(P2PNFT[0].p2pwhitelist(0, ac2))
# pass
P2PNFT[0].mint(0, ac1, {'from': admin})
P2PNFT[0].mint(0, ac2, {'from': admin})
print(P2PNFT[0].balanceOf(ac1,0))

# revert not whitelisted
P2PNFT[0].mint(0, ac3, {'from': admin})
# already minted
P2PNFT[0].mint(0, ac1, {'from': admin})

# soulbound
P2PNFT[0].safeTransferFrom(ac1, ac3, 0, 1, "", {'from' : ac1})
