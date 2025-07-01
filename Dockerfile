# Use a Node.js base image, as firebase-tools relies on Node.js
FROM node:20-alpine

# Install Java (required for Firestore emulator)
RUN apk add --no-cache openjdk11-jre bash curl openssl

# Install Firebase CLI globally
RUN npm install -g firebase-tools

WORKDIR /app
COPY . /app


# Expose ports for the emulators you're using.
EXPOSE 4000
EXPOSE 8080

CMD ["firebase", "emulators:start", "--only", "firestore,ui", "--project", "my-local-test-project"]
