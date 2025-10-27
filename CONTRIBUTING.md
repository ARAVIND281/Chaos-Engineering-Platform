# Contributing to Chaos Engineering Platform

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

---

## Code of Conduct

This project follows a Code of Conduct. By participating, you are expected to uphold this code.

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Accept responsibility for mistakes
- Prioritize community benefit

---

## Getting Started

### Prerequisites

- AWS Account
- AWS CLI configured
- Node.js 18+ and npm
- Git
- TypeScript knowledge
- React/Frontend experience (for UI contributions)

### Finding Issues

- Check [GitHub Issues](https://github.com/yourusername/chaos-engineering-platform/issues)
- Look for `good first issue` label for beginner-friendly tasks
- Check `help wanted` label for high-priority items

---

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/chaos-engineering-platform.git
cd chaos-engineering-platform
```

### 2. Install Dependencies

```bash
# Backend
cd backend
npm install

# Frontend
cd ../frontend
npm install
```

### 3. Deploy to AWS (Optional)

```bash
# Deploy infrastructure for testing
./scripts/deploy-fullstack-complete.sh dev
```

---

## Making Changes

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 2. Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions/modifications

### 3. Make Your Changes

- Write clean, readable code
- Follow existing code style
- Add comments for complex logic
- Update tests as needed
- Update documentation

---

## Pull Request Process

### 1. Commit Your Changes

```bash
git add .
git commit -m "feat: Add new failure injection type"
```

### Commit Message Format

```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting
- `refactor:` - Code restructuring
- `test:` - Adding tests
- `chore:` - Maintenance

### 2. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 3. Create Pull Request

- Go to GitHub and create a Pull Request
- Fill out the PR template
- Link related issues
- Request review from maintainers

### 4. PR Review Process

- Maintainers will review your code
- Address feedback in new commits
- Once approved, your PR will be merged

---

## Coding Standards

### TypeScript/JavaScript

- Use TypeScript for all new code
- Follow ESLint and Prettier rules
- Use meaningful variable names
- Avoid `any` types when possible
- Document public APIs with JSDoc

**Example:**

```typescript
/**
 * Injects a chaos failure into the target instance
 * @param instanceId - The EC2 instance ID
 * @param failureType - Type of failure to inject
 * @returns Promise<ExperimentResult>
 */
export async function injectFailure(
  instanceId: string,
  failureType: FailureType
): Promise<ExperimentResult> {
  // Implementation
}
```

### Python (Lambda Functions)

- Follow PEP 8 style guide
- Use type hints
- Write docstrings for functions
- Keep functions small and focused

### CloudFormation/YAML

- Use consistent indentation (2 spaces)
- Add comments for complex resources
- Follow AWS naming conventions
- Include descriptions for parameters

---

## Testing

### Running Tests

```bash
# Backend tests
cd backend
npm test

# Frontend tests
cd frontend
npm test

# End-to-end tests
./scripts/test-end-to-end.sh
```

### Writing Tests

- Write unit tests for new functions
- Add integration tests for APIs
- Test error handling
- Aim for >80% code coverage

**Example:**

```typescript
describe('injectFailure', () => {
  it('should inject failure into target instance', async () => {
    const result = await injectFailure('i-12345', 'INSTANCE_TERMINATION');
    expect(result.status).toBe('SUCCESS');
  });

  it('should handle invalid instance ID', async () => {
    await expect(injectFailure('invalid', 'INSTANCE_TERMINATION'))
      .rejects
      .toThrow('Invalid instance ID');
  });
});
```

---

## Documentation

### Updating Documentation

- Update README.md for user-facing changes
- Add/update inline code comments
- Update API documentation
- Add examples for new features

### Documentation Structure

```
docs/
├── weeks/           # Weekly implementation guides
├── deployment/      # Deployment instructions
├── fullstack/       # Full-stack architecture docs
└── api/             # API documentation
```

---

## Types of Contributions

### Bug Fixes

1. Reproduce the bug
2. Write a failing test
3. Fix the bug
4. Verify test passes
5. Submit PR

### New Features

1. Discuss in GitHub Issue first
2. Get approval from maintainers
3. Implement feature
4. Add tests
5. Update documentation
6. Submit PR

### Documentation

- Fix typos
- Clarify confusing sections
- Add examples
- Update outdated content

### Infrastructure

- Optimize CloudFormation templates
- Improve deployment scripts
- Enhance monitoring
- Add security improvements

---

## Questions?

- **GitHub Discussions**: Ask questions and share ideas
- **GitHub Issues**: Report bugs and request features
- **Email**: Contact maintainers directly

---

## Recognition

Contributors will be recognized in:
- README.md Contributors section
- Release notes
- Project website (when available)

---

Thank you for contributing to Chaos Engineering Platform! 🚀
