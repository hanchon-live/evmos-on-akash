FROM golang:1.18.3-buster

RUN apt-get update && \
  apt-get install ca-certificates curl gnupg lsb-release make gcc git jq wget unzip -y

RUN git clone https://github.com/evmos/evmos /data
WORKDIR /data
RUN git checkout v6.0.1

RUN make install

RUN evmosd init HanchonEndpoints --chain-id evmos_9001-2
RUN rm $HOME/.evmosd/config/genesis.json

RUN sed -i -e "s%^moniker *=.*%moniker = \"HanchonEndpoints\"%; " $HOME/.evmosd/config/config.toml
# RUN sed -i -e "s%^indexer *=.*%indexer = \"null\"%; " $HOME/.evmosd/config/config.toml
RUN sed -i -e "s%^persistent_peers *=.*%persistent_peers = \"de5dabf3da0efc1a0c0ea9791f111d0b5d0a2aa9@65.108.138.80:34656\"%; " $HOME/.evmosd/config/config.toml

RUN sed -i -e "s%^pruning-keep-recent *=.*%pruning-keep-recent = \"100\"%; " $HOME/.evmosd/config/app.toml
RUN sed -i -e "s%^pruning-keep-every *=.*%pruning-keep-every = \"0\"%; " $HOME/.evmosd/config/app.toml
RUN sed -i -e "s%^pruning-interval *=.*%pruning-interval = \"10\"%; " $HOME/.evmosd/config/app.toml
RUN sed -i -e "s%^snapshot-interval *=.*%snapshot-interval = 0%; " $HOME/.evmosd/config/app.toml

RUN SNAP_RPC1="https://evmos-rpc.polkachu.com:443"; \
SNAP_RPC="https://evmos-rpc.polkachu.com:443"; \
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash); \
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC1\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" ~/.evmosd/config/config.toml

EXPOSE 26656 \
       26657 \
       1317  \
       9090  \
       8545  \
       8080

RUN mv $HOME/.evmosd/data/priv_validator_state.json $HOME/.evmosd/config/

CMD ulimit -n 16392 && \
cd $HOME/.evmosd/config/ && \
mv -n $HOME/.evmosd/config/priv_validator_state.json ../data/priv_validator_state.json && \
wget -nc https://archive.evmos.org/mainnet/genesis.json && \
evmosd start --json-rpc.api eth,txpool,net,web3 --api.enable true --api.enabled-unsafe-cors true --log_level info

