ssh demo@sqlonlinux

# Add the tools to repo
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt update 

# Install tools
sudo ACCEPT_EULA=Y apt install mssql-tools -y

# Add them to path
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
source ~/.bash_profile


# Try connection
sqlcmd -S localhost -U SA -P Passw0rd -Q "SELECT @@Version"
sqlcmd -S sqlonlinux -U SA -P Passw0rd -Q "SELECT @@Version"

exit

# We can also connect from our other machine
$env:SQLCMDPASSWORD="Passw0rd"
sqlcmd -S sqlonlinux -U SA -Q "SELECT @@Version"

# Or use another tool... like SSMS
Start-Process "C:\Program Files (x86)\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe"