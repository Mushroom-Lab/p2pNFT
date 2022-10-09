import requests
import yaml
import json
from flask import Flask, render_template
from flask_cors import CORS
from flask import request
from brownie import accounts

# send tx on-chain once the front end collect all the signatures and metadata
@app.route('/send/tx')
async def send_tx():
    network = request.args.get('network')
    signatures = request.args.get('signatures')
    messageHash = request.args.get('messageHash')
    addresses = request.args.get('addresses')
    if network == 'goerli-optimism':
        web3 = Web3(
            Web3.HTTPProvider(
                OPTIMISM_GOERLI_RPC_PROVIDER
            )
        )
        p2pNFT = p2pNFT_opt
    elif network == 'mumbai-polygon':
        web3 = Web3(
            Web3.HTTPProvider(
                POLYGON_MUMBAI_RPC_PROVIDER
            )
        )
        p2pNFT = p2pNFT_mumbai
    else:
        pass
    admin = accounts.add(private_key=admin_private_key)
    to = p2pNFT
    #signatures, messageHash, addresses
    calldata = 
    gasPrice = web3.eth.gas_price
    tx = await admin.transfer(to=to,amount=0,data=calldata,gas_price=gasPrice)
    # second tx
    # mint
    for 
    tx = calldata
    return 







