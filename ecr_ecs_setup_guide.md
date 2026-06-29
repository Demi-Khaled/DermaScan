# 🐳 DermaScan AI Service — ECR & ECS Fargate Setup Guide

> **Goal:** Push your Python AI service Docker image to ECR, then run it as an ECS Fargate task so your Node.js backend can call it via a private URL.

---

## 📋 Prerequisites

Before starting, make sure you have:

- [ ] **AWS Account** with billing enabled
- [ ] **AWS CLI** installed → [Download here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [ ] **Docker Desktop** installed and running
- [ ] **AWS CLI configured** — run `aws configure` and enter your Access Key, Secret Key, and region (e.g. `us-east-1`)

Verify everything is working:
```bash
aws sts get-caller-identity   # Should print your account ID
docker --version              # Should print Docker version
```

---

## PART 1 — Push Image to ECR

### Step 1: Create the ECR Repository

Go to the **AWS Console → ECR → Create Repository** or run this CLI command:

```bash
aws ecr create-repository \
  --repository-name dermascan-ai \
  --region us-east-1
```

The output will show your **repository URI**. Save it — it looks like:
```
123456789012.dkr.ecr.us-east-1.amazonaws.com/dermascan-ai
```

---

### Step 2: Build the Docker Image

Open a terminal and `cd` into your `ai-service` folder:

```bash
cd "c:\Users\TIFA\Flutter Projects\DermaScan\ai-service"
```

Build the image (this will take 5–10 min the first time due to PyTorch):

```bash
docker build -t dermascan-ai .
```

> ⚠️ The model file (`best_resnet101_model.pth`) is 175 MB — expect the build to take a few minutes.

---

### Step 3: Authenticate Docker to ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS \
  --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com
```

> Replace `123456789012` with your actual AWS Account ID.
> You should see: `Login Succeeded`

---

### Step 4: Tag and Push the Image

```bash
# Tag the local image with the ECR URI
docker tag dermascan-ai:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/dermascan-ai:latest

# Push to ECR (the model layer is 175 MB — first push may take a few minutes)
docker push \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/dermascan-ai:latest
```

✅ You can verify the push in **AWS Console → ECR → dermascan-ai → Images**

---

## PART 2 — Run on ECS Fargate

### Step 5: Create an ECS Cluster

Go to **AWS Console → ECS → Clusters → Create Cluster**:

| Setting | Value |
|---|---|
| **Cluster name** | `dermascan-cluster` |
| **Infrastructure** | AWS Fargate (serverless) |

Click **Create**. ✅

---

### Step 6: Create a Task Definition

Go to **ECS → Task Definitions → Create new Task Definition**:

**Infrastructure:**

| Setting | Value |
|---|---|
| **Task definition name** | `dermascan-ai-task` |
| **Launch type** | AWS Fargate |
| **OS/Architecture** | Linux/X86_64 |
| **CPU** | `1 vCPU` |
| **Memory** | `2 GB` (model needs ~700 MB RAM) |

> 💡 Free Tier does **not** cover Fargate. The cheapest Fargate config (0.25 vCPU / 0.5 GB) costs ~$0.01/hour. Use **1 vCPU / 2 GB** for reliable performance.

**Container configuration (click "Add container"):**

| Setting | Value |
|---|---|
| **Container name** | `dermascan-ai` |
| **Image URI** | `123456789012.dkr.ecr.us-east-1.amazonaws.com/dermascan-ai:latest` |
| **Port mappings** | `5000` → TCP |
| **Health check** | `CMD-SHELL, python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1` |
| **Startup timeout** | `120` seconds (model takes time to load) |

**Logging (very important for debugging):**

Under **Logging**, select **Amazon CloudWatch**:

| Setting | Value |
|---|---|
| **Log group** | `/ecs/dermascan-ai` |
| **Stream prefix** | `ecs` |

Click **Create**. ✅

---

### Step 7: Create a Security Group for the AI Service

Go to **EC2 → Security Groups → Create security group**:

| Setting | Value |
|---|---|
| **Name** | `dermascan-ai-sg` |
| **VPC** | Your VPC (the same one your EC2 backend is in) |

**Inbound Rules:**

| Type | Port | Source | Why |
|---|---|---|---|
| Custom TCP | `5000` | `backend-sg` (the SG of your Node.js EC2) | Only your backend can call the AI |

**Outbound Rules:** Leave default (All traffic allowed — needed to pull from ECR).

> 🔒 This is the **critical security rule**: port 5000 is **NOT** open to the internet, only to your Node.js backend's security group. The AI service is completely private.

---

### Step 8: Create an ECS Service

Go to **ECS → dermascan-cluster → Services → Create**:

| Setting | Value |
|---|---|
| **Launch type** | Fargate |
| **Task Definition** | `dermascan-ai-task` |
| **Service name** | `dermascan-ai-service` |
| **Desired tasks** | `1` |
| **VPC** | Your VPC |
| **Subnets** | Select a **private** subnet (recommended) or public subnet |
| **Security Group** | `dermascan-ai-sg` (created above) |
| **Public IP** | `ENABLED` if using public subnet, `DISABLED` if private |

Click **Create Service**. ✅

---

### Step 9: Get the AI Service Private IP

Once the task is `RUNNING` (takes ~60-90 seconds for the model to load):

1. Go to **ECS → dermascan-cluster → Tasks**
2. Click your running task
3. Under **Network**, copy the **Private IPv4 address** (e.g. `10.0.1.45`)

Your AI service URL will be: `http://10.0.1.45:5000`

> 💡 **The IP changes every time the task restarts.** For a stable URL, use an **Application Load Balancer (ALB)** or **AWS Service Connect** instead. See the optional step below.

---

### Step 10: Connect Your Node.js Backend

SSH into your EC2 instance and update the `.env` file:

```bash
AI_SERVICE_URL=http://10.0.1.45:5000
```

Then restart the Node.js server:

```bash
pm2 restart backend
# or
sudo systemctl restart your-service
```

Test it:
```bash
curl http://10.0.1.45:5000/health
# Expected: {"status": "healthy"}
```

---

## ⭐ Optional (Recommended) — Stable URL with a Load Balancer

If you don't want the IP to change on every restart:

1. Go to **EC2 → Load Balancers → Create → Application Load Balancer**
2. **Scheme:** Internal (private, not internet-facing)
3. **Target group:** IP type, port 5000, health check path `/health`
4. Register your ECS task's IP as a target
5. You get a stable DNS like: `internal-dermascan-ai-alb-xxx.us-east-1.elb.amazonaws.com`

Then set in your `.env`:
```
AI_SERVICE_URL=http://internal-dermascan-ai-alb-xxx.us-east-1.elb.amazonaws.com
```

This URL **never changes**, even if the ECS task is restarted or updated.

---

## 🔄 How to Deploy Updates

Every time you update the AI service code, repeat these steps:

```bash
# 1. Rebuild
docker build -t dermascan-ai .

# 2. Re-tag
docker tag dermascan-ai:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/dermascan-ai:latest

# 3. Push
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/dermascan-ai:latest

# 4. Force ECS to pull the new image (zero-downtime rolling update)
aws ecs update-service \
  --cluster dermascan-cluster \
  --service dermascan-ai-service \
  --force-new-deployment \
  --region us-east-1
```

ECS will automatically start a new task with the new image, wait for it to pass health checks, then stop the old one. **Zero downtime.**

---

## ✅ Final Architecture

```
Flutter App
    │
    ▼ HTTPS
EC2 (Node.js Backend)  ──── Port 5000 ────▶  ECS Fargate (AI Service)
    │                        (private)              │
    ▼                                               ▼
MongoDB Atlas                                  ECR (Docker Image)
Cloudinary                                     CloudWatch Logs
```
