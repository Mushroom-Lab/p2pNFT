# to be used in brownie console
from brownie import *
import os
from brownie import accounts
from dotenv import load_dotenv

load_dotenv()

admin_private_key = os.getenv("PRIVATE_KEY")
admin = accounts.add(private_key=admin_private_key)

def main():
#deployment
    tx=P2PNFTFactory.deploy({'from': admin, "gas_price": "40 gwei"}, publish_source=True)
    

