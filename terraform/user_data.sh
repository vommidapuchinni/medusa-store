#!/bin/bash

# Update the package manager and install required packages
sudo apt-get update -y

# Install Node.js and npm
sudo apt-get install -y nodejs npm

# Install PostgreSQL and set it up
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create PostgreSQL user and database
sudo -u postgres psql -c "CREATE USER medusa_user WITH PASSWORD 'chinni';"
sudo -u postgres psql -c "CREATE DATABASE medusa_db OWNER medusa_user;"

# Install Redis
sudo apt-get install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Install Medusa CLI
sudo npm install -g @medusajs/medusa-cli

# Create and set up a Medusa project
mkdir /medusa
cd /medusa
medusa new my-medusa-store --seed
cd my-medusa-store

# Set environment variables for Medusa
echo "DATABASE_URL=postgres://medusa_user:chinni@localhost:5432/medusa_db" >> .env
echo "REDIS_URL=redis://localhost:6379" >> .env

# Install dependencies and run Medusa
npm install
npm run start

