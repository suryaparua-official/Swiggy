# Documentation Index

Complete guide to Swiggy documentation. Start here to find what you need.

---

## 📚 Quick Navigation

### For Different Roles

**👨‍💼 Project Managers**

- [Architecture Overview](./architecture.md) - System design and components
- [SLOs & Monitoring](./slo.md) - Service level objectives and metrics
- [CI/CD Pipeline](./ci-cd.md) - Deployment process and automation

**👨‍💻 Developers**

- [Development Guide](./development.md) - Local setup, testing, debugging
- [API Reference](./api-reference.md) - All endpoints, request/response formats
- [Database Schema](./database-schema.md) - Collections, relationships, indexes
- [Services Guide](./services.md) - Architecture of each microservice
- [Frontend Documentation](./frontend.md) - React, state management, components

**🔧 DevOps Engineers**

- [Infrastructure Guide](./infrastructure.md) - GCP, GKE, Terraform, networking
- [CI/CD Pipeline](./ci-cd.md) - GitHub Actions, deployments, rollbacks
- [Message Queue Guide](./message-queue.md) - RabbitMQ, event flows, troubleshooting
- [Operational Runbooks](./operational-runbooks.md) - Incident response, troubleshooting

**🚀 New Contributors**

- [Contributing Guide](./CONTRIBUTING.md) - How to contribute, workflow, PRs
- [Development Guide](./development.md) - Set up local environment
- [Local Setup Guide](./local-setup.md) - Quick start instructions

---

## 📖 Documentation by Type

### Architecture & Design

- [Architecture Overview](./architecture.md) - High-level system design
- [Database Schema](./database-schema.md) - Data models and relationships
- [Services Guide](./services.md) - Microservice architecture
- [Frontend Architecture](./frontend.md) - React component structure, state management

### Development

- [Development Guide](./development.md) - Local dev setup, testing, debugging
- [API Reference](./api-reference.md) - Complete API documentation
- [Message Queue Guide](./message-queue.md) - RabbitMQ integration and flows
- [Contributing Guide](./CONTRIBUTING.md) - How to contribute code

### Operations & Deployment

- [Infrastructure Guide](./infrastructure.md) - GCP/GKE setup, Terraform
- [CI/CD Pipeline](./ci-cd.md) - GitHub Actions workflows, deployment process
- [Operational Runbooks](./operational-runbooks.md) - Incident response, troubleshooting
- [Local Setup Guide](./local-setup.md) - Quick local development start

### Monitoring & Management

- [SLOs & Monitoring](./slo.md) - Service level objectives, metrics, alerts
- [Operational Runbooks](./operational-runbooks.md) - Troubleshooting guide

---

## 🚀 Quick Start Paths

### I want to...

**Start developing locally**

1. Read: [Development Guide](./development.md) - Section: Local Development Setup
2. Follow: [Local Setup Guide](./local-setup.md)
3. Reference: [API Reference](./api-reference.md)

**Deploy to production**

1. Read: [Infrastructure Guide](./infrastructure.md)
2. Follow: [CI/CD Pipeline](./ci-cd.md)
3. Reference: [Operational Runbooks](./operational-runbooks.md)

**Understand the system**

1. Read: [Architecture Overview](./architecture.md)
2. Study: [Services Guide](./services.md)
3. Explore: [Database Schema](./database-schema.md)
4. Learn: [Message Queue Guide](./message-queue.md)

**Fix a production issue**

1. Jump to: [Operational Runbooks](./operational-runbooks.md)
2. Check: [SLOs & Monitoring](./slo.md)
3. Reference: [Services Guide](./services.md)

**Contribute code**

1. Read: [Contributing Guide](./CONTRIBUTING.md)
2. Follow: [Development Guide](./development.md)
3. Run: [Local Setup Guide](./local-setup.md)

**Build frontend feature**

1. Study: [Frontend Documentation](./frontend.md)
2. Reference: [API Reference](./api-reference.md)
3. Test: [Development Guide](./development.md) - Section: Testing

---

## 📋 Document Overview

### [📐 Architecture](./architecture.md)

- System components and interactions
- Data flow diagrams
- Technology stack
- Design patterns

**Read this if:** You need to understand the big picture

---

### [🗄️ Database Schema](./database-schema.md)

- Collections and documents
- Relationships and references
- Indexes and optimization
- Query examples
- Data consistency rules

**Read this if:** You're working with data, designing queries, or understanding models

---

### [📡 Message Queue Guide](./message-queue.md)

- RabbitMQ configuration
- Exchanges and queues
- Routing keys and event flows
- Service integration
- Error handling and monitoring

**Read this if:** You're working on event-driven features or integrations

---

### [🏗️ Services Guide](./services.md)

- Auth Service (authentication, JWT)
- Restaurant Service (orders, menus)
- Rider Service (deliveries, locations)
- Utils Service (payments, uploads)
- Admin Service (verification)
- Realtime Service (WebSocket)

**Read this if:** You need details about a specific microservice

---

### [⚛️ Frontend Documentation](./frontend.md)

- Project structure
- React component patterns
- State management (Context API)
- WebSocket integration
- API integration
- Performance optimization

**Read this if:** You're working on the frontend/UI

---

### [💻 Development Guide](./development.md)

- Local environment setup
- Running services locally
- Testing (unit, integration, E2E)
- Code style and conventions
- Debugging techniques
- Troubleshooting

**Read this if:** You're developing locally or need debugging help

---

### [📚 API Reference](./api-reference.md)

- All endpoints by service
- Request/response formats
- Authentication
- Error codes
- Rate limiting

**Read this if:** You're building API clients or need endpoint details

---

### [🌐 Infrastructure Guide](./infrastructure.md)

- GCP project setup
- GKE cluster creation
- Terraform infrastructure-as-code
- Networking and load balancing
- Storage and databases
- Security and IAM
- Scaling and auto-healing

**Read this if:** You're setting up infrastructure or deploying to cloud

---

### [🔄 CI/CD Pipeline](./ci-cd.md)

- GitHub Actions workflows
- CI/CD flow and stages
- Testing in CI
- Docker image building
- Deployment to GKE
- Health checks and rollbacks

**Read this if:** You're deploying code or managing CI/CD

---

### [🚨 Operational Runbooks](./operational-runbooks.md)

- Service health checks
- Pod crash troubleshooting
- Database issues
- Queue backlog handling
- Memory leak detection
- Scaling procedures
- Network troubleshooting
- Incident response checklist

**Read this if:** You're on-call or troubleshooting production issues

---

### [📊 SLOs & Monitoring](./slo.md)

- Service level objectives (SLOs)
- Key metrics and KPIs
- Monitoring setup
- Alerting rules
- Dashboards

**Read this if:** You need to understand service health or set up alerts

---

### [🐳 Local Setup Guide](./local-setup.md)

- Quick start instructions
- Docker Compose setup
- Environment configuration
- Verification steps
- Troubleshooting

**Read this if:** You're setting up local development for the first time

---

### [🤝 Contributing Guide](./CONTRIBUTING.md)

- Code of conduct
- Getting started
- Development workflow
- Pull request process
- Testing requirements
- Commit guidelines
- Code style
- Reporting issues

**Read this if:** You want to contribute to the project

---

## 🔍 Finding Specific Information

### By Topic

**Authentication & Authorization**

- [Services Guide](./services.md#auth-service) → Auth Service section
- [API Reference](./api-reference.md#auth-service) → Auth endpoints

**Order Management**

- [Services Guide](./services.md#restaurant-service) → Restaurant Service
- [Database Schema](./database-schema.md#orders-collection) → Orders collection
- [Message Queue Guide](./message-queue.md) → Order events

**Real-time Updates**

- [Services Guide](./services.md#realtime-service) → Realtime Service
- [Frontend Documentation](./frontend.md#real-time-features) → WebSocket setup
- [Message Queue Guide](./message-queue.md) → Event subscriptions

**Payment Processing**

- [Services Guide](./services.md#utils-service-payment) → Utils Service
- [API Reference](./api-reference.md#utils-service) → Payment endpoints
- [Message Queue Guide](./message-queue.md) → Payment events

**Deployment & DevOps**

- [Infrastructure Guide](./infrastructure.md) → Cloud setup
- [CI/CD Pipeline](./ci-cd.md) → Automated deployments
- [Operational Runbooks](./operational-runbooks.md) → Troubleshooting

**Frontend Development**

- [Frontend Documentation](./frontend.md) → React setup and patterns
- [Development Guide](./development.md) → Testing frontend
- [API Reference](./api-reference.md) → Available endpoints

### By Problem Type

**"Something is broken in production"**
→ [Operational Runbooks](./operational-runbooks.md)

**"I need to fix a bug"**
→ [Development Guide](./development.md) + [Contributing Guide](./CONTRIBUTING.md)

**"I need to add a new feature"**
→ [Contributing Guide](./CONTRIBUTING.md) + relevant service docs

**"I need to understand the data model"**
→ [Database Schema](./database-schema.md)

**"I'm writing a new API endpoint"**
→ [Services Guide](./services.md) + [API Reference](./api-reference.md)

**"I need to deploy changes"**
→ [CI/CD Pipeline](./ci-cd.md)

**"I want to optimize performance"**
→ [SLOs & Monitoring](./slo.md) + service-specific docs

---

## 📦 Repository Structure

```
Swiggy/
├── docs/                          # All documentation (you are here)
│   ├── architecture.md
│   ├── database-schema.md
│   ├── message-queue.md
│   ├── services.md
│   ├── frontend.md
│   ├── development.md
│   ├── api-reference.md
│   ├── infrastructure.md
│   ├── ci-cd.md
│   ├── operational-runbooks.md
│   ├── slo.md
│   ├── local-setup.md
│   ├── CONTRIBUTING.md
│   ├── INDEX.md (this file)
│   └── runbooks/
│       └── pod-crashloop.md
├── frontend/                      # React frontend
├── services/                      # Microservices
│   ├── auth/
│   ├── restaurant/
│   ├── rider/
│   ├── utils/
│   ├── admin/
│   └── realtime/
├── k8s/                          # Kubernetes manifests
├── terraform/                    # Infrastructure as code
├── ansible/                      # Deployment automation
├── .github/workflows/            # CI/CD workflows
└── docker-compose.yml            # Local development
```

---

## 🔗 Cross-References

| Topic            | See Also                                                                                                                      |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Order Processing | [Services](./services.md), [Message Queue](./message-queue.md), [Database](./database-schema.md)                              |
| API Design       | [API Reference](./api-reference.md), [Services](./services.md)                                                                |
| Deployment       | [Infrastructure](./infrastructure.md), [CI/CD](./ci-cd.md), [Runbooks](./operational-runbooks.md)                             |
| Frontend         | [Frontend Guide](./frontend.md), [API Reference](./api-reference.md)                                                          |
| Database         | [Database Schema](./database-schema.md), [Development Guide](./development.md)                                                |
| Real-time        | [Services](./services.md#realtime-service), [Frontend](./frontend.md#real-time-features), [Message Queue](./message-queue.md) |

---

## 📝 Last Updated

Check Git history for individual documents: `git log -- docs/`

```bash
# See when a document was last updated
git log -1 --format="%ai %s" -- docs/api-reference.md

# See all changes to a document
git log --oneline -- docs/api-reference.md
```

---

## 🤝 Contributing to Documentation

Found a typo or outdated information? See [Contributing Guide](./CONTRIBUTING.md).

Documentation improvements are highly valued!

```bash
# Create documentation PR
git checkout -b docs/improve-installation-guide
# Make changes
git commit -m "docs: improve installation guide with additional troubleshooting"
git push origin docs/improve-installation-guide
# Create PR on GitHub
```

---

## 🆘 Getting Help

**Questions about documentation?**

- Open an issue with "documentation" label
- Discuss in project discussions
- Ask in community chat

**Found an error?**

- Create an issue or PR with correction
- Be specific about what's wrong
- Suggest improvement

---

## 📱 Mobile-Friendly Documentation

All documentation is optimized for reading on mobile devices. Use your preferred Markdown viewer.

---

## 🔒 Security Documentation

Security-sensitive documentation (deployment credentials, secrets) is NOT in this repository. It's stored separately in a secure system.

For security-related questions or vulnerability reports: security@suryaparua-official.com

---

## 📊 Documentation Statistics

- **Total Documents:** 13 comprehensive guides
- **Total Pages:** ~150+ markdown pages
- **Code Examples:** 200+
- **Diagrams:** 20+
- **API Endpoints Documented:** 50+
- **Database Collections:** 8 documented
- **Services Documented:** 6 microservices

---

## 🗺️ Documentation Roadmap

Planned documentation additions:

- [ ] Advanced search guide
- [ ] Analytics & reporting
- [ ] Disaster recovery procedures
- [ ] Performance tuning guide
- [ ] Security hardening guide
- [ ] Video tutorials
- [ ] Architecture decision records (ADRs)

---

**Happy reading! 📚**

Start with the [Quick Start section](#quick-start-paths) above if you're unsure where to begin.
