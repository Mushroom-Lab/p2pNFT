import requests
import os
import json
from flask import Flask, render_template
from flask_cors import CORS
from flask import request
from brownie import accounts
from web3 import Web3
from ens import ENS 
from dotenv import load_dotenv

load_dotenv()

nft_storage_key = os.getenv("NFTSTORAGE_KEY")

# RESOLVE ENS
@app.route('/resolveENS')
async def resolveENS():
    web3 = Web3(
            Web3.HTTPProvider(
                MAINNET_PRC_PROVIDER
            )
        )
    ns = ENS.fromWeb3(web3)
    name = request.args.get('name')
    result = ns.address(name)
    return result


# send data to NFT.STORAGE
@app.route('/send/ipfs')
async def send_to_NFTStorage():
    image = request.args.get('image')
    metaData = request.args.get('metadata')
    header = {
        "Authorization": "Bearer {}".format(nft_storage_key)
    }
    r = requests.post("https://api.nft.storage/store", files={"image": image, "meta": json.dumps({'meta': metaData})})
    return r


