# For AD config, we'll again use ConfigMaps
# This time, we use a statefulset (oh, BTW - all in one file!):
code $home\desktop\code\k8s\SQL_Statefulset.yaml
kubectl apply -f $home\desktop\code\k8s\SQL_Statefulset.yaml
kubectl get all

# It gets his own IP:
$SQL_IP=(kubectl get svc mssql-ad -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
sqlcmd -S $SQL_IP -U SA -Q "SELECT @@ServerName"

# Our next step is to create a new keytab:
ssh demo@sqlonlinux 

rm mssql.keytab
echo Passw0rd | kinit demo-adm@DEMO.LCL
adutil spn addauto -n sqlsvc -s MSSQLSvc -H mssql-ad-0.demo.lcl -p 1433 -y
adutil keytab createauto -k mssql.keytab -p 1433 -H mssql-ad-0.demo.lcl --password 'Passw0rd' -s MSSQLSvc -e aes256-cts-hmac-sha1-96,aes128-cts-hmac-sha1-96,aes256-cts-hmac-sha384-192,aes128-cts-hmac-sha256-128,des3-cbc-sha1,arcfour-hmac -y
adutil keytab create -k mssql.keytab -p sqlsvc --password 'Passw0rd' -e aes256-cts-hmac-sha1-96,aes128-cts-hmac-sha1-96,aes256-cts-hmac-sha384-192,aes128-cts-hmac-sha256-128,des3-cbc-sha1,arcfour-hmac
klist -kte mssql.keytab 

exit

# Copy the keytab to the container:
scp demo@sqlonlinux:~/mssql.keytab mssql.keytab 
kubectl cp mssql.keytab mssql-ad-0:/var/opt/mssql/secrets/mssql.keytab

# Add a DNS Record for mssql-ad-0.demo.lcl
Set-Clipboard $SQL_IP
kubectl get svc
mstsc /v:DC /w:1280 /h:720

# And restart the Pod, which is done by deleting it
kubectl delete pod mssql-ad-0

# Authorize our AD User...
sqlcmd -S $SQL_IP -U sa -Q 'CREATE LOGIN [DEMO\DEMO-adm] FROM Windows'

# And use AD auth
sqlcmd -S mssql-ad-0 -Q "SELECT @@Version"

# We could again create a logger.ini and copy it to the Pod for debugging if needed
# kubectl cp logger.ini mssql-ad-0:/var/opt/mssql/logger.ini