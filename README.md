# CS6620 Cloud Computing Course - Educational Git Repository

## 🎯 Educational Branch Structure

**Base Branch:** `week-base-application` (current: audio-interface-for-labelling)
- Contains: Complete Flask app, audio labeling interface, basic deployment files

## ✅ Completed Educational Branches

### **Week 2: `week-02-basic-app`** ✅
**Focus:** Simple SSH deployment with systemd services
**Content:**
- `deploy-simple.sh` - Basic deployment automation
- `ssh-setup-guide.md` - SSH configuration and security
- `systemd-setup.md` - Service management and monitoring
- `troubleshooting-guide.md` - Common deployment issues

### **Week 3: `week-03-networking-dns`** ✅ 🌐
**Focus:** DNS, SSL, and networking fundamentals
**Content:**
- `dns-ssl-guide.md` - Complete DNS and SSL setup
- `duck-dns-setup.sh` - Free DNS automation
- `ssl-letsencrypt.sh` - SSL certificate management
- `cloudflare-setup.md` - CDN and DNS optimization
- **Free Tools:** Duck DNS, Let's Encrypt, Cloudflare

### **Week 4: `week-04-cicd-intro`** ✅ 🚀
**Focus:** CI/CD foundations with GitHub Actions
**Content:**
- `.github/workflows/` - Complete CI/CD pipeline
- `tests/` - Comprehensive test suite with pytest
- `security-testing.md` - Security scanning and SAST
- `deployment-automation.md` - Automated deployment strategies

### **Week 6: `week-06-containerization`** ✅ 🐳
**Focus:** Multi-technology containerization
**Content:**
- `containerization-guide.md` - Docker, Podman, Apptainer comparison
- `Dockerfile` - Multi-stage container build
- `docker-compose.yml` - Service orchestration
- `speech-labeling.def` - Apptainer for HPC environments
- `container-security.md` - Security best practices

### **Week 10: `week-10-traditional-deployment`** ✅ 🏛️
**Focus:** Traditional VM deployment with comprehensive monitoring
**Content:**
- `traditional-deployment-guide.md` - Complete VM deployment
- `setup-iam-roles.sh` - AWS IAM automation
- `setup-vpc.sh` - VPC and networking setup
- `aws-console-setup-guide.md` - Console and CLI approaches
- `monitoring-setup.md` - **Prometheus & Grafana monitoring**
- **Features:** Traditional deployment + modern observability

### **Week 11: `week-11-secrets-management`** ✅ 🔐
**Focus:** Secrets management and encryption
**Content:**
- `secrets-management-guide.md` - AWS Parameter Store integration
- `sops-encryption.md` - Version-controlled secrets with SOPS
- `kms-setup.sh` - AWS KMS configuration
- `app-config-management.md` - Dynamic configuration loading
- **Tools:** AWS Parameter Store, KMS, SOPS

### **Week 13: `week-13-infrastructure-as-code`** ✅ 🏗️
**Focus:** Infrastructure as Code with Terraform
**Content:**
- `infrastructure-as-code-guide.md` - Complete IaC implementation
- `terraform/` - Modular Terraform configuration
- `multi-environment-setup.md` - Environment management
- `ci-cd-integration.md` - IaC in CI/CD pipelines
- **Features:** Multi-environment, state management, best practices

## 🔄 Learning Progression

The educational branches follow a structured progression:

```
week-base-application (Flask app)
├── week-02-basic-app (SSH deployment)
├── week-03-networking-dns (DNS + SSL)
├── week-04-cicd-intro (GitHub Actions)
├── week-06-containerization (Docker + alternatives)
├── week-10-traditional-deployment (VMs + monitoring)
├── week-11-secrets-management (AWS secrets + SOPS)
└── week-13-infrastructure-as-code (Terraform)
```

## 🛠️ Technology Stack by Week

### **Free/Open Source Tools**
- **Week 3:** Duck DNS, Let's Encrypt, Cloudflare
- **Week 4:** GitHub Actions, pytest, security scanning
- **Week 6:** Docker, Podman, Apptainer
- **Week 10:** Prometheus, Grafana, Node Exporter
- **Week 11:** SOPS, age encryption
- **Week 13:** Terraform, open-source modules

### **AWS Services (Free Tier)**
- **Week 10:** EC2, VPC, IAM, Parameter Store
- **Week 11:** KMS, Systems Manager
- **Week 13:** Multi-service infrastructure

## 🎯 Educational Objectives

### **Deployment Evolution**
1. **Traditional (Week 2):** SSH + systemd
2. **Enhanced (Week 3):** + DNS + SSL
3. **Automated (Week 4):** + CI/CD
4. **Containerized (Week 6):** + Docker ecosystem
5. **Production (Week 10):** + VM infrastructure + monitoring
6. **Secure (Week 11):** + Secrets management
7. **Scalable (Week 13):** + Infrastructure as Code

### **Skills Development**
- **System Administration:** SSH, systemd, networking
- **DevOps:** CI/CD, automation, monitoring
- **Containerization:** Docker, Podman, Apptainer
- **Cloud Infrastructure:** AWS, VPC, IAM, security
- **Security:** Secrets management, encryption
- **Infrastructure as Code:** Terraform, state management

## 🚀 Using This Repository

### **For Students**
```bash
# Clone the repository
git clone <repository-url>

# Explore available branches
git branch -a

# Checkout a specific week
git checkout week-03-networking-dns

# Follow the guides in each branch
cat README.md
./deploy-simple.sh
```

### **Branch Structure**
- Each week builds incrementally on previous concepts
- Branches can be used independently for specific topics
- Complete automation scripts for reproducible deployments
- Educational content explains the "why" behind each technology choice

---

*This repository demonstrates the evolution from traditional deployment to modern cloud-native architectures, providing hands-on experience with industry-standard tools and practices.*
