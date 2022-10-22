import time
import json
import os
# from flask import Flask, render_template
# from flask_cors import CORS
# from flask import request

#run bronwie as a packaege
from brownie import *
#from brownie.project.P2PNFT import *
import eth_abi
from hexbytes import HexBytes
from dotenv import load_dotenv

from mnemonic import Mnemonic
from web3 import Web3

from hdwallet import HDWallet
from hdwallet.utils import generate_entropy
from hdwallet.symbols import ETH as SYMBOL

# load .env
load_dotenv()
# load brownie config
p = project.load('./', name="P2PNFT")
p.load_config()

# admin key for sending tx
admin_private_key = os.getenv("PRIVATE_KEY")
admin = accounts.add(private_key=admin_private_key)

# load genosisConfig addresses
def network_config(networkconfig):    
    factor = None
    singleton = None
    fallbackHandler = None
    if networkconfig == 'goerli':
        factor = os.getenv('GOERLI_GENOSIS_FACTORY')
        singleton = os.getenv('GOERLI_GENOSIS_SINGLETON')
        fallbackHandler = os.getenv('GOERLI_GENOSIS_FALLBACKHANDLER')  
    return [factor, singleton, fallbackHandler]

def generateOwnerHD(passphase, index=0 , strength=128):
    # Choose strength 128, 160, 192, 224 or 256
    # Choose language english, french, italian, spanish, chinese_simplified, chinese_traditional, japanese or korean
    LANGUAGE = "english"  # Default is english
    # Generate new entropy hex string
    ENTROPY = generate_entropy(strength=strength)
    # Secret passphrase for mnemonic
    PASSPHRASE = passphase # "meherett"

    hdwallet = HDWallet(symbol=SYMBOL, use_default_path=False)
    # Get Bitcoin HDWallet from entropy
    hdwallet.from_entropy(entropy=ENTROPY, language=LANGUAGE, passphrase=PASSPHRASE)
    # Derivation from path
    index = index
    hdwallet.from_path("m/44'/60'/0'/0/{}".format(index))
    r = hdwallet.dumps()
    return r['addresses']['p2pkh']

#owner is address, admin is an brownie account
def createSafe(factory, singleton, fallbackHandler,owner):
    saltNonce = time.time_ns()
    f = Contract.from_explorer(factory)
    # setup funcSelection
    funcS = '0xb63e800d'
    owners = [owner]
    threshold = 1
    to = admin.address
    data = HexBytes("0000000000000000000000000000000000000000000000000000000000000000")
    paymentToken = "0x0000000000000000000000000000000000000000"
    payment = 0
    paymentReceiver = "0x0000000000000000000000000000000000000000"
    abiEncoded = eth_abi.encode_abi(['address[]', 'uint256', 'address', 'bytes', 'address', 'address', 'uint256', 'address'], [owners, threshold, to , data,  fallbackHandler, paymentToken, payment, paymentReceiver]).hex()
    initializer = funcS + abiEncoded

    tx = f.createProxyWithNonce(singleton, initializer, saltNonce, {'from': admin})
    return tx
# send tx on-chain once the front end collect all the signatures and metadata
@app.route('/send/createSafe')
async def createSafe():
    
    networkOption = request.args.get('networkOption')
    # connect to 8545
    network.connect(networkOption)
    factory, singleton, fallbackHandler = network_config(network)
    owner = generateOwnerHD("aRandomPassphase")
    tx = createSafe(factory, singleton,fallbackHandler, owner)
    print(tx)
    print(tx.events)
    return tx







