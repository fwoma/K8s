# Let's restore some data
if ([System.IO.File]::Exists("AdventureWorks2019.bak") -eq $false) {
curl.exe -L -o AdventureWorks2019.bak https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak
}

kubectl get pods
$Pod=(kubectl get pods -o jsonpath="{.items[0].metadata.name}" )
$Pod
kubectl cp AdventureWorks2019.bak "$($Pod):/var/opt/mssql/data/AdventureWorks2019.bak"

# Our bak is now on the server
kubectl exec -i -t "$($Pod)" -- ls -al /var/opt/mssql/data/AdventureWorks2019.bak

# And we can restore
sqlcmd -S $Endpoint -U SA -Q "RESTORE DATABASE AdventureWorks2019 FROM  DISK = N'/var/opt/mssql/data/AdventureWorks2019.bak' WITH MOVE 'AdventureWorks2019' TO '/var/opt/mssql/data/AdventureWorks2019.mdf', MOVE 'AdventureWorks2019_Log' TO '/var/opt/mssql/data/AdventureWorks2019_Log.ldf'"

sqlcmd -S $Endpoint -U SA -Q "SELECT Name FROM sys.databases"

sqlcmd -S $Endpoint -U SA -Q "SELECT @@version"

# Upgrade to SQL 2022 (or another CU)
kubectl set image deployment mssql-deployment mssql=mcr.microsoft.com/mssql/server:2022-latest

#Check the status of our rollout
kubectl rollout status deployment mssql-deployment

kubectl describe deployment mssql-deployment
kubectl get replicaset

kubectl get pods

kubectl logs (kubectl get pods -o jsonpath="{.items[0].metadata.name}" )

sqlcmd -S $Endpoint -U SA -Q "SELECT @@version"

# We could have also used NFS as our storage
# Let's delete our SQL Server
kubectl delete deployment mssql-deployment
# And also our PVC
kubectl delete pvc sql-storage

# Let's re-define our PVC
code -d $home\desktop\code\k8s\PVC_NFS.yaml $home\desktop\code\k8s\PVC_Local.yaml
kubectl apply -f $home\desktop\code\k8s\PVC_NFS.yaml
kubectl get pvc sql-storage

# And we can then create another SQL Server using the exact same YAML!
kubectl apply -f $home\desktop\code\k8s\SQL.yaml

# Of course, this is using SQL 2019 again, as we didn't change the definition in the YAML:
sqlcmd -S $Endpoint -U SA -Q "SELECT @@version"

# All the advanced settings can go into the YAML file as well
code -d  $home\desktop\code\k8s\SQL_advanced.yaml  $home\desktop\code\k8s\SQL.yaml
kubectl apply -f $home\desktop\code\k8s\SQL_advanced.yaml

# We're now running Enterprise Evaluation Edition
sqlcmd -S $Endpoint -U SA -Q "SELECT @@version"

# And have that traceflag enabled
sqlcmd -S $Endpoint -U SA -Q "DBCC TRACESTATUS"

# But for more complex scenarios, we can also use a configmap
code $home\desktop\code\k8s\mssqlconf.yaml
kubectl apply -f $home\desktop\code\k8s\mssqlconf.yaml

# Our SQL config can then reference this configmap, therefore using our mssql.conf:
code -d  $home\desktop\code\k8s\SQL_Configmap.yaml  $home\desktop\code\k8s\SQL_advanced.yaml
kubectl apply -f $home\desktop\code\k8s\SQL_Configmap.yaml

# We now use another traceflag
sqlcmd -S $Endpoint -U SA -Q "DBCC TRACESTATUS"

# Let's use a LoadBalancer rather than a NodePort Service
kubectl delete svc mssql-deployment
kubectl expose deployment mssql-deployment --target-port=1433 --port 1433 --type=LoadBalancer

# Check our Service- it now has an "external" IP
kubectl get svc

# We can access this IP directly, on Port 1433
$SQL_IP=(kubectl get svc mssql-deployment -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
sqlcmd -S $SQL_IP -U SA -Q "SELECT @@Version"

# Oh, we could also delete the entire namespace
kubectl delete namespace mssql

# And just create everything again (and it could even be all in one file!)
kubectl create namespace mssql
kubectl create secret generic mssql --from-literal=MSSQL_SA_PASSWORD=$PASSWORD
kubectl apply -f $home\desktop\code\k8s\PVC_NFS.yaml
kubectl apply -f $home\desktop\code\k8s\mssqlconf.yaml
kubectl apply -f $home\desktop\code\k8s\SQL_Configmap.yaml
kubectl expose deployment mssql-deployment --target-port=1433 --port 1433 --type=LoadBalancer

# Our (new - because we also deleted the PVCs!) SQL Server is deployed again:
kubectl get all

# And we can access it:
$SQL_IP=(kubectl get svc mssql-deployment -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
sqlcmd -S $SQL_IP -U SA -Q "SELECT @@Version"
