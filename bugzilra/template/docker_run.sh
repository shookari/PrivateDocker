#!/bin/bash
source ./env

# TODO docker image name check
chk_con=`docker ps -a | grep -w $CONTAINER | wc -l`
chk_img=`docker images | grep -w $IMAGE | wc -l`
tmp_con=`docker ps -a | grep -w $TEMPLATE_CONTAINER | wc -l`
if [ $chk_img -ne 0 ] || [ $chk_con -ne 0 ] ||  [ $tmp_con -ne 0 ] ;then
    echo "FAIL: Already exist name: confirm image, container name from env file" 
    exit 1
fi

if [ ! -e $BKUP_DATA ]; then
    echo "FAIL: check BKUP_DATA :[$BKUP_DATA]"
    exit 1
fi

echo "Recovery Info************************************"
echo "Bugzilra Data: $BKUP_DATA"
echo "IMAGE: $TEMPLATE_IMAGE ==> $IMAGE"
echo "Generate Container : $TEMPLATE_CONTAINER"
echo "************************************************"

docker tag $TEMPLATE_IMAGE $IMAGE

docker run -p 49999:80 -d \
    --add-host="$HOSTNAME:$HOSTIP" \
    --hostname=$HOSTNAME \
    --name=$TEMPLATE_CONTAINER \
    --privileged=false \
    -it $IMAGE

# Send backup data to container
sudo docker cp ./recover.sh $TEMPLATE_CONTAINER:/root/
sudo docker cp ./data $TEMPLATE_CONTAINER:/root/
sudo docker exec $TEMPLATE_CONTAINER /root/recover.sh /root/$BKUP_DATA

if [ $? -eq 0 ]; then
    echo "Bugzilra recovery succ"
    echo "Generate Image:$IMAGE/ Container:$CONTAINER "
    sudo docker cp run_bugzilra.sh $TEMPLATE_CONTAINER:/root
    sudo docker stop $TEMPLATE_CONTAINER
    sudo docker commit $TEMPLATE_CONTAINER $IMAGE
    sudo docker rm $TEMPLATE_CONTAINER
    echo "Clean temporary Image and container"
else
    echo "Bugzilra recovery fail"
    echo "check backupfile, step log"
fi
