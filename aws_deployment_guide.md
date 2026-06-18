# AWS Deployment Guide: AI Service to ECS Fargate

Great news: Your `ai-service` code is **already 100% production-ready** for AWS ECS Fargate! 

The codebase already contains:
- A multi-stage `Dockerfile` optimized to keep the PyTorch footprint small.
- A `gunicorn.conf.py` file configured to bind to `0.0.0.0:5000` and preload the model into RAM to prevent ECS memory spikes.
- A `/health` endpoint in `app.py` specifically designed for ECS Target Group health checks.
- A non-root Docker user (`appuser`) for cloud security.

Here are the exact steps to deploy it to AWS and connect it to your backend.

---

## Phase 1: Push to Elastic Container Registry (ECR)

First, we need to upload your Docker image to AWS.

1. **Create an ECR Repository:**
   Go to the AWS Console -> ECR -> Create repository. Name it `dermascan-ai`.

2. **Authenticate Docker with ECR:**
   Open your terminal in the `ai-service` folder and run this:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 277707109446.dkr.ecr.us-east-1.amazonaws.com
   ```

3. **Build the Docker Image:**
   (You can skip this if you already built it locally!)
   ```bash
   docker build -t dermascan-ai .
   ```

4. **Tag and Push the Image:**
   ```bash
   docker tag dermascan-ai:latest 277707109446.dkr.ecr.us-east-1.amazonaws.com/dermascan-ai:latest
   docker push 277707109446.dkr.ecr.us-east-1.amazonaws.com/dermascan-ai:latest
   ```

---

## Phase 2: Create the Task Definition

Since your service creation failed, it's often due to misconfigured Task Definitions or Networking. Let's get the Task Definition exactly right:

1. Go to **ECS -> Task definitions -> Create new task definition**.
2. **Task definition family:** `dermascan-ai-task`
3. **Launch type:** AWS Fargate
4. **OS / Architecture:** Linux / X86_64
5. **Task size:**
   - **CPU:** `1 vCPU`
   - **Memory:** `3 GB` (PyTorch needs this headroom to prevent OutOfMemory errors)
6. **Container - 1:**
   - **Name:** `dermascan-ai`
   - **Image URI:** Paste your exact ECR URI (e.g., `...amazonaws.com/dermascan-ai:latest` or the SHA hash)
   - **Essential container:** Yes
7. **Port mappings:**
   - **Container port:** `5000`
   - **Protocol:** `TCP`
   - **App protocol:** `HTTP`
   - ⚠️ **CRITICAL:** *Remove* the default port `80` if it is there. Your app only uses `5000`.
8. **Resource allocation limits (Container-level):**
   - **Memory hard limit:** `3 GB`
   - **Memory soft limit:** `2 GB` (Do not set this too low!)
9. Click **Create**.

---

## Phase 3: Create the ECS Cluster & Service

1. **Create an ECS Cluster:**
   - Go to ECS -> Clusters -> Create Cluster. 
   - Name it `dermascan-cluster`.
   - Infrastructure: AWS Fargate (Serverless). Create it.

2. **Create the Service:**
   - Open your `dermascan-cluster` and click **Create Service** under the Services tab.
   - **Compute configuration:** Launch type -> Fargate
   - **Deployment configuration:**
     - **Application type:** Service
     - **Task definition:** `dermascan-ai-task` (Latest revision)
     - **Service name:** `ai-service`
     - **Desired tasks:** `1`
   - **Networking:**
     - **VPC:** Select your default VPC.
     - **Subnets:** Select all available subnets.
     - **Security group:** Create a new security group.
       - Rule 1: Type `Custom TCP`, Port `5000`, Source `Anywhere` (or your EC2's specific IP/Security Group for better security).
     - **Public IP:** ⚠️ **TURN THIS ON.** If your subnets are public and you don't have a NAT Gateway, Fargate needs a public IP to pull the Docker image from ECR. If this is off, the service will fail with a `CannotPullContainerError`.
3. Click **Create**.

### Troubleshooting Service Failures:
If the service still fails to start, check the **Tasks** tab in your cluster, change the filter from "Running" to "Any desired status" or "Stopped":
1. Click on the stopped task -> **Logs** tab. If there's a Python/Gunicorn error, you'll see it here.
2. Check the **Details** tab -> look for the "Stopped reason" at the bottom. 
   - If it says `ResourceInitializationError: unable to pull secrets or registry auth...`, you likely forgot to enable the **Public IP** in the networking settings.
   - If it says `OutOfMemory`, you need to increase the Task and Container memory limits.

---

## Phase 4: Connect the EC2 Backend

Once the ECS task says **"RUNNING"**, you need to link it to your Node.js backend.

1. **Get the ECS Task IP:**
   Click on your running ECS Task. Under the "Configuration" tab, find the **Private IPv4 address** (if your EC2 and ECS are in the same VPC) or the **Public IPv4 address** (if crossing networks).
   *Example: `10.0.1.155`*

2. **Update the Node.js Backend:**
   SSH into your EC2 instance where the Node.js backend is hosted.
   Open your `.env` file:
   ```bash
   nano .env
   ```

3. **Change the AI URL:**
   Update the `AI_SERVICE_URL` to point to the ECS IP on port 5000:
   ```env
   # Replace this IP with your ECS Task's actual IP
   AI_SERVICE_URL=http://10.0.1.155:5000
   ```

4. **Restart your Backend:**
   If you are using PM2 to run Node.js:
   ```bash
   pm2 restart backend
   ```
   Or if you are just using npm:
   ```bash
   npm run dev
   ```

### You're Done! 🎉
When your Flutter app makes a scan request, the EC2 Node backend will securely forward the image to your ECS Fargate Python container, run the AI model, and return the result.
