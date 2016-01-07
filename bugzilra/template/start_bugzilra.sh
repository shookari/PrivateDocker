#!/bin/bash
source ./env

# Generate container
sudo docker run -p 49999:80 -d \
    --add-host="$HOSTNAME:$HOSTIP" \
    --hostname=$HOSTNAME \
    --name=$CONTAINER \
    --privileged=false \
    -it $IMAGE

# Run bugzilra 
sudo docker exec $CONTAINER /root/run_bugzilra.sh &
