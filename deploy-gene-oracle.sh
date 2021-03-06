#!/bin/sh

#Purpose: Instantiate a gene-oracle pod with a given number of containers.

#Command line arguments
# $1 - number of containers
# $2 - input data dir - input data folders must be named "data-<experiment_number>". See README for more info.


######
#TODO: Add "nodeSelector" attribute to run gene-oracle on specific nodes
######

#Generate beginning of pod file
cat > ./gene-oracle-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: gene-oracle
spec:
  containers:
EOF

#Add framework of n containers to end of file
for i in $(seq 1 $1); do
    echo "  - name: gene-oracle-container-$i" >> ./gene-oracle-pod.yaml
    echo "    image: docker.io/ctargon/gene-oracle" >> ./gene-oracle-pod.yaml
    echo "    imagePullPolicy: Always" >> ./gene-oracle-pod.yaml
    echo "    resources:" >> ./gene-oracle-pod.yaml
    echo "      limits:" >> ./gene-oracle-pod.yaml
    echo "        nvidia.com/gpu: 1" >> ./gene-oracle-pod.yaml
done

#User confirms generated framework is correct
echo "Generated pod framework:"
cat ./gene-oracle-pod.yaml
sleep 5

#Start pod
echo "Instantiating pod..."
kubectl create -f gene-oracle-pod.yaml

#Wait for pod to start
status="$(kubectl get pod gene-oracle | awk '{ print $2 }' | tail -n +2)"
while [ "$status" != "Running" ]
do
echo "Waiting for pod to start...$status"
sleep 2
status="$(kubectl get pod gene-oracle | awk '{ print $3 }' | tail -n +2)"
done

#User confirms pod is running correctly
kubectl get pod gene-oracle
echo "IF YOU DO NOT SEE YOUR POD NAME, KILL THIS SCRIPT"
sleep 2

#Copy data and start gene-oracle in each container
for i in $(seq 1 $1); do
    echo "Copying data...$i"
    kubectl cp $2/data deepgtex-prp/gene-oracle:/gene-oracle -c gene-oracle-container-$i &
    sleep 5
    echo "Starting gene-oracle...$i"
    kubectl exec gene-oracle -c gene-oracle-container-$i -- /bin/bash -c "/gene-oracle/run-gene-oracle.sh" &
    sleep 1
done



