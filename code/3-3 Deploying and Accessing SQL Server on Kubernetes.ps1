# We'll create a Namespace
kubectl create namespace mssql
kubectl get namespace
kubectl config set-context --current --namespace=mssql

# It's empty
kubectl get pods

# We'll start with an SA Password
$PASSWORD='Passw0rd'
$env:SQLCMDPASSWORD=$PASSWORD
kubectl create secret generic mssql --from-literal=MSSQL_SA_PASSWORD=$PASSWORD

kubectl get secret mssql -o yaml

# And define storage
code $home\desktop\code\k8s\PVC_Local.yaml
kubectl apply -f $home\desktop\code\k8s\PVC_Local.yaml
kubectl get pvc

# We can then define our SQL Server
code $home\desktop\code\k8s\SQL.yaml
kubectl apply -f $home\desktop\code\k8s\SQL.yaml

# Our storage is now bound
kubectl get pvc

# And SQL is coming up
kubectl get deployment
kubectl get pod -w 

# We can also check out the logs of the Pod which is the SQL Log
kubectl logs (kubectl get pods -o jsonpath="{.items[0].metadata.name}" )

# But we can't access it yet...
# Instead of YAML we can also use imperative commands
kubectl expose deployment mssql-deployment --target-port=1433 --type=NodePort

# We now have a service
kubectl get service

$Endpoint= ("k8s-worker-1,$(kubectl get service mssql-deployment -o jsonpath='{ .spec.ports[*].nodePort }')")
$Endpoint
sqlcmd -S $Endpoint -U SA -Q "SELECT @@VERSION"


