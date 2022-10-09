import requests
import yaml
import json
from flask import Flask, render_template
from flask_cors import CORS
from flask import request

from web3 import Web3
from ens import ENS 
from dotenv import load_dotenv

from brownie import accounts
load_dotenv()


admin_private_key = os.getenv("PRIVATE_KEY")
nftStorageKey = os.getenv("NFTSTORAGE_KEY")
# web3 provider
MAINNET_PRC_PROVIDER = os.getenv('MAINNET_PRC_PROVIDER')
POLYGON_MUMBAI_RPC_PROVIDER = os.getenv("POLYGON_MUMBAI_RPC_PROVIDER")
OPTIMISM_GOERLI_RPC_PROVIDER = os.getenv("OPTIMISM_GOERLI_RPC_PROVIDER")
#addresses
p2pNFT_opt = os.getenv("p2pNFT_opt")
p2pNFT_mumbai = os.getenv("p2pNFT_mumbai")



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
    result = await ns.address(name)
    return result


# send data to NFT.STORAGE
@app.route('/send/metadata')
async def send_to_NFTStorage():
    image = request.args.get('image')
    metaData = request.args.get('metadata')
    header = {
        "Authorization": "Bearer {}".format(nft_storage_key)
    }
    r = await requests.post("https://api.nft.storage/store", files={"image": image, "meta": json.dumps({'meta': metaData})})
    return 


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





