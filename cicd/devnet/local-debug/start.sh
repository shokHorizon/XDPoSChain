#!/bin/bash
if [ ! -d work/xdcchain/XDC/chaindata ]
then
  # Randomly select a key from environment variable, seperated by ','
  if test -z "$PRIVATE_KEYS" 
  then
        echo "PRIVATE_KEYS environment variable has not been set. You need to pass at least one PK, or you can pass multiple PK seperated by ',', we will randomly choose one for you"
        exit 1
  fi
  IFS=', ' read -r -a private_keys <<< "$PRIVATE_KEYS"
  private_key=${private_keys[ $RANDOM % ${#private_keys[@]} ]}

  echo "${private_key}" >> /tmp/key
  echo "Creating a new wallet"
  wallet=$(./../../../build/bin/XDC account import --password .pwd --datadir work/xdcchain /tmp/key | awk -v FS="({|})" '{print $2}')
  ./../../../build/bin/XDC --datadir work/xdcchain init ../genesis.json
else
  echo "Wallet already exist, re-use the same one"
  wallet=$(./../../../build/bin/XDC account list --datadir work/xdcchain | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

input="../bootnodes.list"
bootnodes=""
while IFS= read -r line
do
    if [ -z "${bootnodes}" ]
    then
        bootnodes=$line
    else
        bootnodes="${bootnodes},$line"
    fi
done < "$input"

log_level=1
if test -z "$LOG_LEVEL" 
then
  echo "Log level not set, default to verbosity of 3"
else
  echo "Log level found, set to $LOG_LEVEL"
  log_level=$LOG_LEVEL
fi

INSTANCE_IP="159.196.170.6"
netstats="LOCAL-${NODE_NAME}-${wallet}-${INSTANCE_IP}:xinfin_xdpos_hybrid_network_stats@devnetstats.apothem.network:2000"


echo "Running a node with wallet: ${wallet} at IP: ${INSTANCE_IP}"
echo "Starting nodes with $bootnodes ..."

./../../../build/bin/XDC --ethstats ${netstats} --gcmode=archive \
--nat extip:${INSTANCE_IP} \
--bootnodes ${bootnodes} --syncmode full \
--datadir work/xdcchain --networkid 551 \
-port 30303 --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 \
--rpcport 8545 \
--rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,XDPoS \
--rpcvhosts "*" --unlock "${wallet}" --password .pwd --mine \
--gasprice "1" --targetgaslimit "420000000" --verbosity ${log_level} \
--ws --wsaddr=0.0.0.0 --wsport 8555 \
--wsorigins "*" 2>&1 >>work/xdcchain/xdc.log
