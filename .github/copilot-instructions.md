# Development Guidelines

## Core Philosophy
Build well-structured, maintainable applications following industry best practices and established design principles.

## General Principles

### Code Quality
- Write clean, readable, and maintainable code
- Follow language-specific conventions and idioms
- Keep functions/methods small and focused
- Use meaningful names that reflect intent
- Avoid premature optimization

### Testing
- Write tests using the project's testing framework RSpec
- Focus on testing behavior, not implementation
- Keep test coverage high but pragmatic
- Use factories for test data when available

### Security
- Follow security best practices for all code generation
- Never hardcode secrets or sensitive data
- Always validate and sanitize user input
- Use strong parameters and parameterized queries
- See `.github/instructions/security.instructions.md` for complete guidelines

### Documentation
- Write self-documenting code through clear naming
- Add comments for complex logic or business rules
- Keep README and documentation up to date

## Project-Specific Guidelines

For language and framework-specific guidelines, refer to:
- **Security**: See `.github/instructions/security.instructions.md` for security best practices and vulnerability prevention
- **Rails**: See `.github/instructions/rails.instructions.md` for Rails MVC patterns and Majestic Monolith approach
- **API**: See `.github/instructions/api.instructions.md` for RESTful API development patterns and best practices
- **Ruby**: See `.github/instructions/ruby.instructions.md` for Ruby code quality and SOLID principles
- **RSpec**: See `.github/instructions/rspec.instructions.md` for RSpec testing patterns and best practices
- **Test Coverage**: See `.github/instructions/test-coverage.instructions.md` for coverage requirements and guidelines
- **Git Commits**: See `.github/git-commit-instructions.md` for conventional commit message format


