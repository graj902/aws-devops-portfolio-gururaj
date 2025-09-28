# Use a specific, official Node.js runtime as a parent image for reproducibility
FROM node:18-alpine AS builder

# Set the working directory in the container
WORKDIR /app

# Copy package files and install dependencies in a separate layer to leverage Docker cache
COPY package*.json ./
RUN npm install

# Copy the rest of the application source code
COPY . .

# --- Production Stage ---
# Start from a clean, lightweight Node.js image
FROM node:18-alpine

WORKDIR /app

# Copy only the necessary installed dependencies and application code from the builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/src ./src
COPY --from=builder /app/public ./public

# Make port 8080 available to the world outside this container
EXPOSE 8080

# Define the command to run the app
CMD [ "node", "src/index.js" ]