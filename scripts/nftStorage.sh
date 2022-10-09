cd Desktop
curl --request POST https://api.nft.storage/store -F image=@demo.jpg -F meta='{"image":null,"name":"Storing the Worlds Most Valuable Virtual Assets with NFT.Storage","description":"The metaverse is here. Where is it all being stored?","properties":{"type":"blog-post"}}' --header "Authorization: Bearer $NFTSTORAGE_KEY"
