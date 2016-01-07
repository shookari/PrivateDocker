source ./env

# Run bugzilra 
sudo docker stop $CONTAINER
echo "stop $CONTAINER"
sudo docker rm $CONTAINER
echo "rm $CONTAINER"
