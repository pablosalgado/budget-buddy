---
description: 'Git commit message guidelines and best practices'
---

# Git Commit Message Guidelines

When generating or suggesting git commit messages, follow these best practices:

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type (Required)

Choose one:
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring (no feature change, no bug fix)
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks (dependencies, configs, etc.)
- **ci**: CI/CD changes
- **build**: Build system changes

### Scope (Optional)

The area affected:
- **api**: API changes
- **ui**: User interface
- **auth**: Authentication
- **db**: Database
- **models**: Model changes
- **controllers**: Controller changes
- **services**: Service objects
- **config**: Configuration
- **deps**: Dependencies

### Subject (Required)

- Use imperative mood ("add" not "added" or "adds")
- Don't capitalize first letter
- No period at the end
- Maximum 50 characters
- Be clear and concise

### Body (Optional but Recommended)

- Wrap at 72 characters
- Explain **what** and **why**, not **how**
- Separate from subject with blank line
- Use bullet points if needed

### Footer (Optional)

- Reference issues: `Closes #123`, `Fixes #456`
- Breaking changes: `BREAKING CHANGE: description`

## Examples

### Good Examples

```
feat(api): add health check endpoint

Replace the superfluous examples endpoint with an industry-standard
health check that verifies database and cache connectivity.

- Adds GET /api/v1/health endpoint
- Returns status, timestamp, version, and environment
- Includes database and cache health checks
- Comprehensive test coverage (5 specs)

Closes #42
```

```
fix(auth): prevent token expiration race condition

Users were occasionally logged out during active sessions due to
token refresh timing issues.

- Add 5-minute grace period before token expiration
- Implement token refresh mutex to prevent concurrent refreshes
- Add spec coverage for race condition scenario

Fixes #89
```

```
refactor(models): extract budget calculation to service object

Move complex budget calculation logic from Budget model to
BudgetCalculatorService following SOLID principles.

- Improves testability
- Reduces model complexity
- Follows single responsibility principle
```

```
docs: update API development guidelines

Remove AI-First messaging and simplify documentation structure.
The instruction files speak for themselves.
```

```
test(api): add request specs for budget endpoints

- Add comprehensive CRUD operation tests
- Test success and error cases
- Test pagination and filtering
- All status codes verified
```

```
chore(deps): update Rails to 8.1.1

Update Rails and related gems to latest stable versions.
No breaking changes in this update.
```

### Bad Examples

```
❌ Fixed bug
```
*Why bad: No type, vague, past tense*

```
❌ feat: Added new feature for users to create budgets with validation
```
*Why bad: Too long (>50 chars), past tense, combines multiple changes*

```
❌ Update files
```
*Why bad: No type, too vague, doesn't explain what or why*

```
❌ WIP
```
*Why bad: Work in progress commits should be squashed before merging*

```
❌ feat(api): Add budget endpoint, update docs, fix tests, refactor service
```
*Why bad: Multiple changes in one commit - should be separate commits*

## Best Practices

### 1. Atomic Commits
- One logical change per commit
- If you use "and" in the subject, it's probably multiple commits
- Each commit should pass all tests

### 2. Commit Often
- Commit logical units of work
- Don't wait until everything is "perfect"
- Can always squash later if needed

### 3. Write for Humans
- Imagine someone reading git log to understand project history
- Future you will thank present you for clear messages
- Clear commits make code review easier

### 4. Use Present Tense (Imperative Mood)
```
✅ add feature
❌ added feature
❌ adds feature
```

### 5. Explain Why, Not Just What
```
✅ refactor(auth): extract JWT logic to service

The authentication controller was becoming too complex.
Extracting JWT encoding/decoding to a service improves
testability and follows single responsibility principle.

❌ refactor(auth): move code to service
```

### 6. Reference Issues
```
✅ fix(api): handle null user in budget controller

Fixes #123
```

### 7. Break Down Large Changes
Instead of:
```
❌ feat: implement entire budget feature
```

Do:
```
✅ feat(models): add Budget model with validations
✅ feat(api): add budget CRUD endpoints
✅ feat(api): add budget pagination and filtering
✅ test(api): add comprehensive budget specs
✅ docs: document budget API endpoints
```

## Conventional Commits

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification.

Benefits:
- Automatically generate CHANGELOGs
- Automatically determine semantic version bumps
- Communicate nature of changes to teammates
- Trigger build and publish processes
- Make it easier for people to contribute

## Tools

### Commit Message Template

Add to `~/.gitmessage`:
```
# <type>(<scope>): <subject>
# |<---- Max 50 chars ---->|

# <body>
# |<---- Wrap at 72 characters ---->|

# <footer>

# Type: feat, fix, docs, style, refactor, perf, test, chore, ci, build
# Scope: api, ui, auth, db, models, controllers, services, config, deps
# Subject: Imperative mood, no capital, no period
# Body: Explain what and why, not how
# Footer: Issues (Closes #123), Breaking changes
```

Set globally:
```bash
git config --global commit.template ~/.gitmessage
```

## Summary

When writing commit messages:
1. ✅ Use conventional commit format
2. ✅ Choose appropriate type and scope
3. ✅ Write clear, imperative subject (<50 chars)
4. ✅ Add body for non-trivial changes
5. ✅ Reference issues in footer
6. ✅ One logical change per commit
7. ✅ Explain why, not just what
8. ✅ Make it easy for others to understand project history

