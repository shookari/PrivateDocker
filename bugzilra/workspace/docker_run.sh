IMAGE="bug1.2"
HOSTNAME="bugzilra1.2"
HOSTIP="172.17.0.3"

docker run -p 49999:80 -d -e \
    --add-host="$HOSTNAME:$HOSTIP" \
    --hostname=$HOSTNAME \
    --name=$HOSTNAME \
    -it $IMAGE
