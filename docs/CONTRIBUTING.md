# Contributing Guide

Guidelines for contributing to Swiggy project.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Commit Guidelines](#commit-guidelines)
- [Code Style](#code-style)
- [Documentation](#documentation)
- [Reporting Issues](#reporting-issues)
- [Questions & Support](#questions--support)

---

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please read and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

**Be respectful, inclusive, and constructive in all interactions.**

---

## Getting Started

### 1. Fork the Repository

```bash
# On GitHub: Click "Fork" button on https://github.com/suryaparua-official/Swiggy
git clone https://github.com/YOUR-USERNAME/Swiggy.git
cd Swiggy
git remote add upstream https://github.com/suryaparua-official/Swiggy.git
```

### 2. Set Up Development Environment

```bash
# Install dependencies
npm install

# Set up Git hooks
npm run prepare  # This runs husky setup

# Verify setup
npm run lint
npm run test
```

### 3. Verify Local Setup

```bash
# Start local environment
docker-compose up -d

# Run tests
npm test

# You should see all tests passing
```

---

## Development Workflow

### 1. Create Feature Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create new branch (use descriptive name)
git checkout -b feature/add-order-tracking

# Valid branch prefixes:
# - feature/  → New feature
# - bugfix/   → Bug fix
# - hotfix/   → Critical production fix
# - refactor/ → Code refactoring
# - docs/     → Documentation
# - chore/    → Maintenance tasks
```

### 2. Make Your Changes

**For backend services:**

```bash
cd services/restaurant
npm run dev

# Make changes, see them reload instantly
```

**For frontend:**

```bash
cd frontend
npm run dev

# Visit http://localhost:5173
```

### 3. Write Tests

**Add unit tests for any new code:**

```bash
# Create test file alongside your code
src/utils/orderflow.ts        → src/utils/orderflow.test.ts
src/controllers/order.ts      → src/controllers/order.test.ts

# Run tests
npm test

# Watch mode while developing
npm test -- --watch
```

**Test coverage expectations:**

- New code: ≥ 80% coverage
- Critical functions: ≥ 90% coverage
- Modified code: Maintain or improve existing coverage

### 4. Commit Changes

```bash
# Stage changes
git add .

# Commit (follow convention)
git commit -m "feat(restaurant): add order tracking feature

- Add real-time order status updates
- Integrate with WebSocket service
- Update order model schema

Closes #123"

# Verify commit format
npm run lint-commit
```

**Commit message format:**

```
<type>(<scope>): <subject>

<body>

<footer>

Type: feat, fix, docs, style, refactor, test, chore
Scope: The component/module being changed (optional)
Subject: < 50 chars, imperative mood, no period
Body: Explain what and why, not how
Footer: Reference issues (Closes #123)
```

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/add-order-tracking

# Create PR on GitHub
# - Title: Follows conventional commits
# - Description: Explain changes, link issues, mention testing
# - Request reviewers
```

---

## Pull Request Process

### PR Requirements

- [ ] Tests written and passing
- [ ] Coverage maintained or improved
- [ ] Code follows style guide
- [ ] Documentation updated
- [ ] No console logs or debug code
- [ ] Follows conventional commit format
- [ ] Linked to relevant issue

### PR Template

```markdown
## Description

Brief explanation of changes made.

## Type of Change

- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update

## Related Issue

Closes #123

## Testing Done

Describe testing performed:

- [ ] Unit tests added
- [ ] Integration tests passed
- [ ] Manual testing completed

## Screenshots (if UI change)

Add relevant screenshots.

## Checklist

- [ ] Code follows style guide
- [ ] No new warnings generated
- [ ] Tests added and passing
- [ ] Documentation updated
- [ ] Rebased on main
```

### Review Process

1. **Automated Checks** (GitHub Actions)
   - Linting passes
   - Tests pass
   - Build succeeds
   - Coverage maintained

2. **Code Review** (Team members)
   - Architecture review
   - Code quality
   - Testing coverage
   - Documentation completeness

3. **Approval & Merge**
   - Requires 2 approvals for main branch
   - All checks must pass
   - Squash commits before merge

---

## Testing Requirements

### Unit Tests

**Backend (Jest):**

```typescript
import { OrderService } from "./order.service";

describe("OrderService", () => {
  let service: OrderService;

  beforeEach(() => {
    service = new OrderService();
  });

  it("should create order with valid data", async () => {
    const orderData = {
      restaurantId: "rest-1",
      items: [{ menuItemId: "item-1", quantity: 2 }],
      totalAmount: 500,
    };

    const result = await service.createOrder(orderData);

    expect(result).toBeDefined();
    expect(result.orderId).toBeTruthy();
    expect(result.orderStatus).toBe("pending");
  });

  it("should throw for invalid data", async () => {
    expect(() => service.createOrder({})).rejects.toThrow("Invalid order");
  });
});
```

**Frontend (Vitest):**

```typescript
import { render, screen } from '@testing-library/react';
import { OrderCard } from './OrderCard';

describe('OrderCard', () => {
  it('renders order information', () => {
    const order = {
      id: 'ord-1',
      status: 'delivered',
      total: 500
    };

    render(<OrderCard order={order} />);

    expect(screen.getByText('Order #ord-1')).toBeInTheDocument();
    expect(screen.getByText('₹500')).toBeInTheDocument();
  });
});
```

### Integration Tests

```bash
# Tests that involve database, RabbitMQ, etc.
npm run test:integration

# Requires docker-compose services running
```

### E2E Tests

```bash
# End-to-end browser tests
cd frontend
npm run test:e2e

# Opens Playwright test browser
```

### Running All Tests

```bash
npm test                    # All tests once
npm test -- --watch       # Watch mode
npm test -- --coverage    # With coverage report
```

---

## Commit Guidelines

### Conventional Commits

Following [Conventional Commits](https://www.conventionalcommits.org/) format:

**Format:**

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `style` - Code style (formatting, semicolons, etc.)
- `refactor` - Code refactoring
- `perf` - Performance improvement
- `test` - Adding or updating tests
- `chore` - Build process, dependencies, etc.

**Examples:**

```
feat(auth): add JWT token refresh endpoint
fix(restaurant): resolve menu item deletion race condition
docs(api): update API reference for order endpoints
style(frontend): format button component with prettier
refactor(rider): simplify location tracking logic
perf(database): add indexes for order queries
test(utils): add payment verification tests
chore: update dependencies
```

### Commit Best Practices

- [ ] One logical change per commit
- [ ] Descriptive but concise messages
- [ ] Imperative mood ("add" not "added")
- [ ] Reference issues when relevant
- [ ] Include body for complex changes

---

## Code Style

### TypeScript

```typescript
// Strict mode enabled
// No implicit any
// No unused variables

// Interface over type for object shapes
interface User {
  id: string;
  email: string;
  role: "customer" | "restaurant" | "rider";
}

// Descriptive variable names
const userOrders = orders.filter((o) => o.userId === userId);

// Document complex logic
/**
 * Calculates delivery fee based on distance and zone
 * @param distance Distance in kilometers
 * @param zone Delivery zone identifier
 * @returns Delivery fee in INR
 */
function calculateDeliveryFee(distance: number, zone: string): number {
  // ...
}
```

### React Component

```typescript
// Functional components with hooks
interface Props {
  orderId: string;
  onDelete?: () => void;
}

export const OrderCard: React.FC<Props> = ({ orderId, onDelete }) => {
  const [order, setOrder] = useState<Order | null>(null);

  useEffect(() => {
    // Fetch logic
  }, [orderId]);

  return (
    <div className="order-card">
      {order && <p>{order.status}</p>}
    </div>
  );
};
```

### Linting & Formatting

```bash
# Check style
npm run lint

# Auto-fix issues
npm run lint:fix

# Format with Prettier
npm run format

# Check if formatted
npm run format:check
```

---

## Documentation

### Code Comments

```typescript
// Good: Explains why, not what
// We batch order confirmations every 5 seconds to reduce RabbitMQ traffic
const BATCH_INTERVAL = 5000;

// Bad: Obvious from code
// Set batch interval to 5000
const BATCH_INTERVAL = 5000;

// For complex logic, use JSDoc
/**
 * Process incoming orders and publish to message queue
 * @param orders Array of pending orders
 * @returns Number of successfully published orders
 * @throws Error if RabbitMQ connection fails
 */
async function publishOrders(orders: Order[]): Promise<number> {
  // ...
}
```

### README Updates

- If adding new service, update service docs
- If changing API, update API reference
- If modifying setup, update development guide

### Commit in Documentation Changes

```bash
docs(api-reference): add webhook endpoint documentation
docs(development): update local setup instructions
docs(services): add restaurant service architecture diagram
```

---

## Reporting Issues

### Issue Templates

Use appropriate template when creating issues:

- **Bug Report** - Something isn't working
- **Feature Request** - Suggest new functionality
- **Documentation** - Missing or unclear docs

### Bug Report Format

```markdown
## Description

Brief description of the bug.

## Steps to Reproduce

1. Go to...
2. Click on...
3. Observe...

## Expected Behavior

What should happen.

## Actual Behavior

What actually happened.

## Environment

- OS: [e.g., Windows, macOS, Linux]
- Browser: [e.g., Chrome, Firefox]
- Version: [Commit hash or version number]

## Screenshots

If applicable, add screenshots.

## Logs

Include relevant error logs or console output.
```

### Feature Request Format

```markdown
## Description

Clear description of the desired feature.

## Use Case

Why this feature is needed.

## Proposed Solution

How the feature should work (optional).

## Alternative Solutions

Other approaches considered (optional).
```

---

## Questions & Support

### Getting Help

1. **GitHub Discussions** - General questions
2. **GitHub Issues** - Bug reports and features
3. **Slack/Discord** - Real-time chat (if available)
4. **Email** - Critical issues

### Asking Good Questions

- Search existing issues/discussions first
- Provide context and reproducible example
- Include relevant logs and error messages
- Be specific about what you tried

---

## Security Reporting

**Do not create public issues for security vulnerabilities.**

Report security issues to: security@swiggy-org.email

- Describe the vulnerability
- Include steps to reproduce
- Allow 48 hours before public disclosure

---

## Review Checklist for Reviewers

- [ ] Code quality and style
- [ ] Tests written and adequate
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Performance impact reviewed
- [ ] Security considerations addressed
- [ ] Commits properly formatted

---

## Useful Resources

- [Architecture Documentation](./architecture.md)
- [API Reference](./api-reference.md)
- [Development Guide](./development.md)
- [Database Schema](./database-schema.md)
- [Message Queue Guide](./message-queue.md)
- [Services Documentation](./services.md)
- [CI/CD Pipeline](./ci-cd.md)

---

## Recognition

Contributors will be recognized in:

- [CONTRIBUTORS.md](../CONTRIBUTORS.md)
- Monthly contributor highlights
- GitHub sponsors (if applicable)

---

## License

By contributing to Swiggy, you agree that your contributions will be licensed under the same license as the project (see [LICENSE.md](../LICENSE.md)).

---

**Thank you for contributing to Swiggy! 🎉**

We appreciate your effort and look forward to collaborating with you!
