# Steps to Create a Local Containerized Firebase Emulator Suite

This guide will walk you through setting up a local Firebase development environment using Docker, allowing you to run Firestore and Realtime Database (and other services) in isolated containers.

## Prerequisites:

* **Docker Desktop** (or Docker Engine) installed and running on your machine.
* **Node.js** and **npm** installed (required for Firebase CLI).
* **Firebase CLI** installed globally: `npm install -g firebase-tools`

---

## Step 1: Initialize Your Firebase Project Locally

If you don't already have a local Firebase project setup, you'll need to do so to create the necessary `firebase.json` configuration file.

1.  **Navigate to your project's root directory** in your terminal where you want to set up your Firebase project.
2.  **Initialize Firebase:**
    ```bash
    firebase init
    ```
3.  **Follow the prompts:**
    * Select "Yes" when asked if you want to proceed.
    * Choose "Use an existing project" or "Create a new project" (for local emulation, the actual project ID doesn't matter much here, but it's good practice to use a meaningful placeholder like `my-local-test-project`).
    * **Crucially, select the features you want to emulate.** Use the spacebar to select:
        * `Firestore: Configure and deploy Cloud Firestore security rules and indexes`
        * `Realtime Database: Configure and deploy Realtime Database Rules`
        * **(Optional but Recommended):** `Emulators: Set up local emulators for Firebase products`
        * **(Optional):** `Functions: Configure and deploy Cloud Functions` (if you plan to use them)
    * Accept the default file names (e.g., `firestore.rules`, `database.rules.json`).
    * If you selected "Emulators", say "Yes" to "Set up emulators now?".

    This process will create a `firebase.json` file in your project root, which defines the configuration for your Firebase services.

---

## Step 2: Configure Emulator Suite Settings

This step ensures your `firebase.json` is set up to run the emulators and defines their ports.

1.  **Ensure `firebase.json` includes an `emulators` section:**
    If you didn't select "Emulators" during `firebase init`, or if you need to reconfigure, run:
    ```bash
    firebase init emulators
    ```
2.  **Follow the prompts:**
    * Select the emulators you want to run (e.g., Firestore, Realtime Database, Authentication, Functions, Storage, Hosting).
    * Accept the default ports (or customize them if needed, but remember them for Docker port mapping). Typical ports are:
        * Firestore: `8080`
        * Realtime Database: `9000`
        * Authentication: `9099`
        * Functions: `5001`
        * Emulator UI: `4000`
        * Cloud Storage: `9199`
    * This will add or update the `emulators` section in your `firebase.json` file. For example:
        ```json
        {
          "emulators": {
            "firestore": {
              "port": 8080
            },
            "database": {
              "port": 9000
            },
            "auth": {
              "port": 9099
            },
            "functions": {
              "port": 5001
            },
            "ui": {
              "port": 4000
            },
            "storage": {
              "port": 9199
            }
          }
        }
        ```

---

## Step 3: Create a `Dockerfile` for the Emulator Suite

This Dockerfile will install the necessary tools and run the Firebase emulators within a container.

1.  **Create a new file named `Dockerfile`** in the root of your Firebase project.
2.  **Add the following content** to the `Dockerfile`:

    ```dockerfile
    # Use a Node.js base image, as firebase-tools relies on Node.js
    FROM node:20-alpine

    # Install Java (required for Firestore and Realtime Database emulators)
    # and other necessary tools like bash, curl, openssl
    RUN apk add --no-cache openjdk11-jre bash curl openssl

    # Install Firebase CLI globally
    RUN npm install -g firebase-tools

    # Set working directory inside the container
    WORKDIR /app

    # Copy your entire Firebase project files into the container
    # This includes firebase.json, rules, functions code, etc.
    COPY . /app

    # Expose ports for the emulators you're using.
    # These should match the ports in your firebase.json or defaults.
    EXPOSE 4000 # Emulator UI
    EXPOSE 8080 # Firestore
    EXPOSE 9000 # Realtime Database
    EXPOSE 9099 # Authentication
    EXPOSE 5001 # Functions
    EXPOSE 9199 # Storage

    # Command to start the Firebase emulators
    # Use --only to specify which emulators to run. Adjust as needed.
    # --host 0.0.0.0 makes the emulators accessible from outside the container
    CMD ["firebase", "emulators:start", "--only", "firestore,database,auth,functions,storage,ui", "--host", "0.0.0.0"]
    ```

---

## Step 4: Create a `docker-compose.yml` File (Recommended)

Using `docker-compose` simplifies running and managing your containerized emulator suite.

1.  **Create a new file named `docker-compose.yml`** in the root of your Firebase project (alongside your `Dockerfile`).
2.  **Add the following content** to the `docker-compose.yml`:

    ```yaml
    version: '3.8' # Use a recent Docker Compose version

    services:
      firebase-emulator:
        build: . # Build the image using the Dockerfile in the current directory
        ports:
          # Map container ports to host ports. Adjust as needed based on your firebase.json.
          - "4000:4000" # Emulator UI
          - "8080:8080" # Firestore
          - "9000:9000" # Realtime Database
          - "9099:9099" # Authentication
          - "5001:5001" # Functions
          - "9199:9199" # Storage
        environment:
          # Important for emulators to bind correctly within Docker
          - FIRESTORE_EMULATOR_HOST=0.0.0.0:8080
          - DATABASE_EMULATOR_HOST=0.0.0.0:9000
          - AUTH_EMULATOR_HOST=0.0.0.0:9099
          - FUNCTIONS_EMULATOR_HOST=0.0.0.0:5001
          - STORAGE_EMULATOR_HOST=0.0.0.0:9199
          # You can set a dummy project ID for the emulator if your code relies on it
          - FIREBASE_PROJECT_ID=my-local-test-project
        volumes:
          # Mount your local project directory into the container.
          # This allows the container to pick up firebase.json, rules, functions, etc.
          - .:/app
          # Optional: Persist emulator data (e.g., Firestore documents) across container restarts.
          # This creates a Docker volume named 'firebase-data'.
          - firebase-data:/app/firebase-emulator-data

    volumes:
      firebase-data: # Define the named volume for persistence
    ```

---

## Step 5: Build and Run the Docker Container

Now, you're ready to spin up your local Firebase Emulator Suite.

1.  **Open your terminal** and navigate to the root directory of your Firebase project (where `Dockerfile` and `docker-compose.yml` are located).
2.  **Build and run the container(s) in detached mode:**
    ```bash
    docker-compose up --build -d
    ```
    * `--build`: Builds the Docker image (if it doesn't exist or if `Dockerfile` has changed).
    * `-d`: Runs the containers in detached mode (in the background).

3.  **Verify the emulators are running:**
    You should see output indicating the services are starting. You can check the logs:
    ```bash
    docker-compose logs -f firebase-emulator
    ```
    (Press `Ctrl+C` to exit logs).

4.  **Access the Emulator UI:**
    Open your web browser and go to: `http://localhost:4000`
    This UI provides a visual interface to see your database data, function logs, authentication users, and more.

---

## Step 6: Connect Your Java Application to the Local Emulators

Finally, configure your Java application to use the local emulators instead of connecting to the Firebase cloud services.

1.  **Update your Java code** where you initialize the Firebase Admin SDK. You'll need to set system properties or environment variables *before* `FirebaseApp.initializeApp()`.

    ```java
    import com.google.auth.oauth2.GoogleCredentials;
    import com.google.firebase.FirebaseApp;
    import com.google.firebase.FirebaseOptions;
    import com.google.firebase.cloud.FirestoreClient;
    import com.google.firebase.database.FirebaseDatabase;
    import com.google.firebase.auth.FirebaseAuth;
    import com.google.firebase.cloud.StorageClient;

    import java.io.FileInputStream;
    import java.io.IOException;

    public class FirebaseEmulatorConfig {

        public static void initializeLocalFirebase() {
            // !!! IMPORTANT: Set these system properties BEFORE initializing FirebaseApp !!!
            System.setProperty("FIRESTORE_EMULATOR_HOST", "localhost:8080");
            System.setProperty("FIREBASE_DATABASE_EMULATOR_HOST", "localhost:9000");
            System.setProperty("FIREBASE_AUTH_EMULATOR_HOST", "localhost:9099");
            System.setProperty("FIREBASE_STORAGE_EMULATOR_HOST", "localhost:9199");
            System.setProperty("FIREBASE_FUNCTIONS_EMULATOR_HOST", "localhost:5001"); // If using functions callable from client

            try {
                // Even when using emulators, the Admin SDK typically requires credentials for initialization.
                // However, the emulator host settings will redirect traffic locally.
                // For local development, you might point to a dummy service account or skip if you use
                // default credentials from your dev environment.
                // For simplicity, a placeholder is used here. In a real app, load your service account.
                // You can usually point to a dummy JSON file or use a placeholder if your app doesn't
                // strictly rely on specific credentials for local emulation.
                // Or, if running locally, and you've run 'gcloud auth application-default login',
                // GoogleCredentials.getApplicationDefault() might work.
                FileInputStream serviceAccount = new FileInputStream("path/to/your/serviceAccountKey.json");

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        // Set the project ID to the one you used when initializing the emulator
                        .setProjectId("my-local-test-project")
                        // If using Realtime Database, you might set a dummy URL here,
                        // but the emulator host property will override it.
                        // .setDatabaseUrl("[https://my-local-test-project-default-rtdb.firebaseio.com](https://my-local-test-project-default-rtdb.firebaseio.com)")
                        .build();

                FirebaseApp.initializeApp(options);
                System.out.println("Firebase Admin SDK initialized for local emulators.");

                // Example usage:
                // Firestore firestore = FirestoreClient.getFirestore();
                // DatabaseReference rtdb = FirebaseDatabase.getInstance().getReference();
                // FirebaseAuth auth = FirebaseAuth.getInstance();
                // StorageClient storage = StorageClient.getInstance();

            } catch (IOException e) {
                System.err.println("Error initializing Firebase: " + e.getMessage());
                e.printStackTrace();
            }
        }

        public static void main(String[] args) {
            initializeLocalFirebase();
            // Your application logic here, interacting with FirestoreClient.getFirestore(), etc.
        }
    }
    ```

    * **Crucial:** The `System.setProperty()` calls **must happen before `FirebaseApp.initializeApp()`**.
    * Replace `"path/to/your/serviceAccountKey.json"` with the actual path to a Firebase service account key JSON file. While the emulators don't strictly *validate* these credentials, the Firebase Admin SDK initialization process generally expects them. For local development, a minimal or placeholder file might suffice if you don't have a real one handy, as the traffic is rerouted locally.

---

## Step 7: Stop the Emulators (When Done)

When you're finished with your development session, stop the containers.

1.  **In your terminal**, navigate to your project root.
2.  **Stop the running containers:**
    ```bash
    docker-compose down
    ```
    This will stop and remove the `firebase-emulator` container. If you used the `firebase-data` volume for persistence, the data will remain for future runs.