## SQL on Linux
ssh demo@sqlonlinux

# Add the repo key
sudo wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Add SQL Server repo (adjust path for different versions of Ubuntu etc.)
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2022.list)"

# Install SQL Server
sudo apt update
sudo apt install mssql-server -y

# Configure SQL Server
sudo /opt/mssql/bin/mssql-conf setup

# Add Traceflag
sudo /opt/mssql/bin/mssql-conf traceflag 3205 on

# Restart SQL Server
sudo systemctl restart mssql-server.service

# Install Agent
sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true
sudo systemctl restart mssql-server.service

# Check logs
journalctl -u mssql-server -e --all
