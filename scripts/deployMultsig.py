# example: https://goerli.etherscan.io/tx/0xb1799a3fc99425a0f0497f4e98ae66244345b583a712c108e3288f0ddd81893e#eventlog

# to be used in brownie console
from brownie import *
import os
from dotenv import load_dotenv

import eth_abi
from hexbytes import HexBytes
#from eth_account.messages import encode_defunct, encode_structured_data

# deploy 1 with 1 owner

# test can only be in goerli
ac1_private_key = os.getenv("AC2")
ac1 = accounts.add(private_key=ac1_private_key)

#goerli config, use others for other network
factory = '0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2'
singleton = '0x3e5c63644e683549055b9be8653de26e0b4cd36e'
fallbackHandler = "0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4"
saltNonce = time.time_ns()

#create createProxyWithNonce(address _singleton, bytes initializer, uint256 saltNonce)
# 0x1688f0b9
# initialize need to build this argument
# funcSelector of setup
#  0xb63e800d
# address[] calldata _owners,
#         uint256 _threshold,
#         address to,
#         bytes calldata data,
#         address fallbackHandler,
#         address paymentToken,
#         uint256 payment,
#         address payable paymentReceiver

# before that load explorer config according to network-config.yaml
f = Contract.from_explorer(factory)
#w3.eth.build_transaction

funcS = '0xb63e800d'
owners = [ac1.address]
threshold = 1
to = ac1.address
data = HexBytes("0000000000000000000000000000000000000000000000000000000000000000")
paymentToken = "0x0000000000000000000000000000000000000000"
payment = 0
paymentReceiver = "0x0000000000000000000000000000000000000000"
abiEncoded = eth_abi.encode_abi(['address[]', 'uint256', 'address', 'bytes', 'address', 'address', 'uint256', 'address'], [owners, threshold, to , data,  fallbackHandler, paymentToken, payment, paymentReceiver]).hex()
initializer = funcS + abiEncoded

f.createProxyWithNonce(singleton, initializer, saltNonce, {'from': ac1})
