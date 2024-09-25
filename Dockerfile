# Use official Node.js image as a base
FROM node:18-alpine

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of your application code
COPY . .

# Expose the port the app will run on
EXPOSE 9000

# Set environment variables for the database
ENV DATABASE_URL=postgres://medusa_user:chinni@db:5432/medusa_db

# Start the application
CMD ["npm", "run", "start:custom"]

