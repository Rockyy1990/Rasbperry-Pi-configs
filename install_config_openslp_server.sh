#!/bin/bash

# Installs and config an openslp server

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt update && sudo apt upgrade -y

# Install OpenSLP
echo "Installing OpenSLP..."
sudo apt install -y openslp

# Check if the installation was successful
if ! dpkg -l | grep -q openslp; then
    echo "OpenSLP installation failed. Exiting..."
    exit 1
fi

# Configure OpenSLP
echo "Configuring OpenSLP..."
SLP_CONF="/etc/openslp/openslp.conf"

# Create a backup of the original configuration file
sudo cp $SLP_CONF $SLP_CONF.bak

# Modify the configuration file
sudo bash -c "cat > $SLP_CONF <<EOL
# OpenSLP Configuration File
# Listen on all interfaces
net.slp.listenURLs=slp://:427
# Default discovery URL
net.slp.defaultScopes=default
# Local Service Registration
net.slp.localScopes=default
# LogLevel
net.slp.logLevel=INFO
EOL"

# Start OpenSLP service
echo "Starting OpenSLP service..."
sudo systemctl start openslp

# Enable OpenSLP to start on boot
echo "Enabling OpenSLP to start on boot..."
sudo systemctl enable openslp

# Check the status of OpenSLP service
echo "Checking the status of OpenSLP service..."
sudo systemctl status openslp

echo "OpenSLP installation and configuration complete."
