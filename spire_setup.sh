#clone repo https://github.com/spiffe/spire-tutorials

cd ~/spire/spire-tutorials-main/k8s/quickstart

kubectl apply -f spire-namespace.yaml

#Verify
kubectl get namespaces

#Create Server Bundle Configmap, Role & ClusterRoleBinding
kubectl apply \
    -f server-account.yaml \
    -f spire-bundle-configmap.yaml \
    -f server-cluster-role.yaml

#Create Server Configmap
kubectl apply \
    -f server-configmap.yaml \
    -f server-statefulset.yaml \
    -f server-service.yaml

#This creates a statefulset called spire-server in the spire namespace and starts up a spire-server pod, as demonstrated in the output of the following commands:
kubectl get statefulset --namespace spire
kubectl get pods --namespace spire

#***********************************************#Configure and deploy the SPIRE Agent****************************************
#To allow the agent read access to the kubelet API to perform workload attestation, a Service Account and ClusterRole must be 
#created that confers the appropriate entitlements to Kubernetes RBAC, and that ClusterRoleBinding must be associated with the 
#service account created in the previous step.
kubectl apply \
    -f agent-account.yaml \
    -f agent-cluster-role.yaml

#Apply the agent-configmap.yaml configuration file to create the agent configmap and deploy the Agent as a daemonset that runs 
#one instance of each Agent on each Kubernetes worker node.
kubectl apply \
    -f agent-configmap.yaml \
    -f agent-daemonset.yaml

#This creates a daemonset called spire-agent in the spire namespace and starts up a spire-agent pod along side spire-server, 
#as demonstrated in the output of the following commands:
kubectl get daemonset --namespace spire


#*********************************************************Register Workloads********************************************************
#In order to enable SPIRE to perform workload attestation – which allows the agent to identify the workload to attest to its agent 
#you must register the workload in the server. This tells SPIRE how to identify the workload and which SPIFFE ID to give it.

#1-Create a new registration entry for the node, specifying the SPIFFE ID to allocate to the node:
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s_sat:cluster:demo-cluster \
    -selector k8s_sat:agent_ns:spire \
    -selector k8s_sat:agent_sa:spire-agent \
    -node

#Create a new registration entry for the workload, specifying the SPIFFE ID to allocate to the workload:
kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/default/sa/default \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:ns:default \
    -selector k8s:sa:default

#In this section, you configure a workload container to access SPIRE. Specifically, you are configuring the workload container to access the Workload API UNIX domain socket.
#The client-deployment.yaml file configures a no-op container using the spire-k8s docker image used for the server and agent. Examine the volumeMounts and volumes c
#onfiguration stanzas to see how the UNIX domain agent.sock is bound in.
#You can test that the agent socket is accessible from an application container by issuing the following commands:
#Apply the deployment file:
kubectl apply -f client-deployment.yaml

#Verify that the container can access the socket:
kubectl exec -it $(kubectl get pods -o=jsonpath='{.items[0].metadata.name}' \
   -l app=client)  -- /opt/spire/bin/spire-agent api fetch -socketPath /run/spire/sockets/agent.sock

#********************************Tear Down All Components*******************************************************************
kubectl delete deployment client
kubectl delete namespace spire