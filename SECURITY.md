# Security

This is a personal learning project. Security measures are in place to practice good habits and protect against common vulnerabilities.

---

## Security Measures

### Automated Security Scanning

This project uses multiple layers of automated security scanning:

#### 1. **Brakeman** - Static Code Analysis
- **What**: Scans Ruby code for security vulnerabilities
- **When**: Every pull request and weekly
- **Config**: `config/brakeman.yml`
- **Detects**: SQL injection, XSS, command injection, mass assignment, etc.

#### 2. **Bundler Audit** - Dependency Vulnerability Scanner
- **What**: Checks gems against CVE database
- **When**: Every pull request and weekly
- **Config**: `config/bundler-audit.yml`
- **Detects**: Known vulnerabilities in dependencies

#### 3. **Dependabot** - Automated Dependency Updates
- **What**: Creates PRs for dependency updates
- **When**: Weekly on Mondays
- **Config**: `.github/dependabot.yml`
- **Updates**: Ruby gems, GitHub Actions, npm packages

#### 4. **RuboCop Security** - Additional Security Cops
- **What**: Enforces security best practices
- **When**: Every pull request
- **Detects**: Unsafe YAML loading, insecure random, eval usage, etc.

#### 5. **TruffleHog** - Secret Scanning
- **What**: Detects accidentally committed secrets
- **When**: Weekly scheduled scans
- **Detects**: API keys, passwords, tokens in code/commits

---

## Security Best Practices

When working on this project:

1. **Never commit secrets**
   - Use environment variables for sensitive data
   - Check `.env.example` for required variables
   - Never hardcode API keys, passwords, or tokens

2. **Use strong parameters**
   - Always use `params.require().permit()` in controllers
   - Never use `params.permit!`

3. **Validate input**
   - Add model validations for all user input
   - Use parameterized queries, never string interpolation in SQL

4. **Keep dependencies updated**
   - Review Dependabot PRs
   - Update vulnerable dependencies promptly

---

## Known Security Status

### Not Yet Implemented

- Authentication
- Rate Limiting  
- CORS configuration

---

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Brakeman Scanner](https://brakemanscanner.org/)

---

*Personal learning project - Last updated: January 7, 2026*


