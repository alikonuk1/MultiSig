source .env

forge script script/Factory.s.sol:FactoryScript --rpc-url $GOERLI_RPC_URL \
    --broadcast -vvvv --verify

forge script script/MultiSig.s.sol:MultiSigScript --rpc-url $GOERLI_RPC_URL \
    --broadcast -vvvv --verify