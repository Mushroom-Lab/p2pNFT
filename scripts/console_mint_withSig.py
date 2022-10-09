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

p2pnft = os.getenv('p2pNFT_mumbai')
ac2_private_key = os.getenv("AC2")
ac2 = accounts.add(private_key=ac2_private_key)

# test message
message = "bafyreihkxnh7jnxmbzfzkuk2pcz7fncli5tkqjmtjttqzqbxs6rcsvcmpy"
cid = "bafyreihkxnh7jnxmbzfzkuk2pcz7fncli5tkqjmtjttqzqbxs6rcsvcmpy"
# team hash : bafyreihkxnh7jnxmbzfzkuk2pcz7fncli5tkqjmtjttqzqbxs6rcsvcmpy
ac1 = "0xd8C19B45061B8fc74136c06Ee5CB464e6aa7CbbA"
signature = "0xb3bf43ffaef04034616c2646fba8f7c8c296a068c20d4c108f62c8c893fde4e7374020712b8cd83468de5eafbba476137b01a63d303f482b4ac81bc1cdd10c4b1c"
# convert this message to 32bytes
rawMessageHash = Web3.keccak(text=message)

abiEncoded = eth_abi.encode_abi(['address[]', 'bytes32'], [[ac1,ac2.address], rawMessageHash])
# this is what we have to sign
hashed = Web3.solidityKeccak(['bytes'], ['0x' + abiEncoded.hex()]).hex()

#0x8f5cfeee1e97fda7ffd139aaef1e16cb26e18ceeae10087faa0717e2f215b5b7?
message = encode_defunct(hexstr=hashed)
ac1_signed = signature
ac2_signed = w3.eth.account.sign_message(message, private_key=ac2_private_key)

# check addresses
print(w3.eth.account.recover_message(message, signature=ac1_signed))
print(w3.eth.account.recover_message(message, signature=ac2_signed.signature))

p = P2PNFT.at(p2pnft)
#good example
tx = p.initilizeNFT(HexBytes(ac1_signed) + ac2_signed.signature, rawMessageHash, [ac1 ,ac2.address],cid, {'from': ac2})
print(tx.events)
print(p.p2pwhitelist(1,ac1))
print(p.p2pwhitelist(1, ac2))
# pass
p.mint(1, ac1, {'from': ac2})
p.mint(1, ac2, {'from': ac2})
print(p.balanceOf(ac1,0))

