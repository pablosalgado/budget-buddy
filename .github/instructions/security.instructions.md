---
description: 'Security best practices and guidelines for code generation'
---

# Security Guidelines

## Core Security Principles

When generating code, always follow these non-negotiable security practices:

### 1. Never Hardcode Secrets

❌ **NEVER DO THIS:**
```ruby
class StripeService
  API_KEY = "sk_live_51H7xYz2eZvKYlo2C..."  # DISASTER!
  SECRET = "my_secret_password"
end
```

✅ **ALWAYS DO THIS:**
```ruby
class StripeService
  API_KEY = ENV.fetch('STRIPE_API_KEY')
  SECRET = Rails.application.credentials.stripe_secret
end
```

**Why**: Hardcoded secrets in code end up in git history forever, exposing your application to attacks.


---

### 2. Always Use Strong Parameters

❌ **NEVER DO THIS:**
```ruby
def create
  @user = User.create(params[:user])  # Mass assignment vulnerability!
end
```

✅ **ALWAYS DO THIS:**
```ruby
def create
  @user = User.create(user_params)
end

private

def user_params
  params.require(:user).permit(:name, :email, :password)
end
```

**Why**: Prevents attackers from setting arbitrary attributes (like `admin: true`).

---

### 3. Use Parameterized Queries

❌ **NEVER DO THIS:**
```ruby
# SQL Injection vulnerability
User.where("email = '#{params[:email]}'")
User.where("name LIKE '%#{params[:search]}%'")
```

✅ **ALWAYS DO THIS:**
```ruby
# Safe - parameterized
User.where(email: params[:email])
User.where("name LIKE ?", "%#{params[:search]}%")
```

**Why**: String interpolation in SQL allows SQL injection attacks.

---

### 4. Validate All User Input

❌ **INSUFFICIENT:**
```ruby
class Budget < ApplicationRecord
  # No validations
end
```

✅ **REQUIRED:**
```ruby
class Budget < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :category, inclusion: { in: %w[income expense] }
end
```

**Why**: Never trust user input. Validate format, length, type, and allowed values.

---

### 5. Sanitize HTML Output

❌ **XSS VULNERABILITY:**
```erb
<!-- User input rendered raw -->
<%= @comment.body %>
<%= raw @user.bio %>
```

✅ **SAFE:**
```erb
<!-- Automatically escaped by Rails -->
<%= @comment.body %>

<!-- If you need HTML, sanitize it -->
<%= sanitize @user.bio, tags: %w[p br strong em] %>
```

**Why**: Prevents cross-site scripting (XSS) attacks.

---

### 6. Implement Proper Authentication

✅ **REQUIRED FOR PRODUCTION:**
```ruby
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_request
  
  private
  
  def authenticate_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    
    begin
      decoded = JsonWebToken.decode(token)
      @current_user = User.find(decoded[:user_id])
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
```

**Why**: Protect sensitive endpoints from unauthorized access.

---

### 7. Implement Authorization Checks

❌ **SECURITY FLAW:**
```ruby
def update
  @budget = Budget.find(params[:id])
  @budget.update(budget_params)  # Any user can update any budget!
end
```

✅ **REQUIRED:**
```ruby
def update
  @budget = current_user.budgets.find(params[:id])  # Scope to current user
  @budget.update(budget_params)
end
```

**Why**: Authentication says WHO you are, authorization says WHAT you can do.

---

### 8. Use Secure Random for Tokens

❌ **PREDICTABLE:**
```ruby
token = rand(1000000).to_s  # Can be guessed!
```

✅ **SECURE:**
```ruby
token = SecureRandom.hex(32)
token = SecureRandom.urlsafe_base64(32)
```

**Why**: `rand` is predictable. Use cryptographically secure random for tokens.

---

### 9. Protect Against CSRF

✅ **Rails handles this automatically for HTML:**
```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception  # Already enabled by default
end
```

✅ **For APIs, use token authentication:**
```ruby
class Api::V1::BaseController < ActionController::API
  # No CSRF protection needed - stateless authentication via tokens
end
```

**Why**: Prevents cross-site request forgery attacks.

---

### 10. Never Log Sensitive Data

❌ **PRIVACY VIOLATION:**
```ruby
Rails.logger.info("User logged in: #{user.email}, password: #{params[:password]}")
Rails.logger.debug("Credit card: #{params[:cc_number]}")
```

✅ **SAFE:**
```ruby
Rails.logger.info("User logged in: #{user.id}")
# Passwords, credit cards, tokens - NEVER log them!
```

**Why**: Logs may be stored insecurely or seen by unauthorized personnel.

---

## Security Checklist for Generated Code

When generating controllers, models, or services, ensure:

- [ ] No hardcoded secrets (use ENV vars or credentials)
- [ ] Strong parameters used for all user input
- [ ] All database queries are parameterized
- [ ] Model validations present for all user-modifiable fields
- [ ] HTML output is escaped (or explicitly sanitized)
- [ ] Authentication required for protected endpoints
- [ ] Authorization checks scope data to current user
- [ ] SecureRandom used for tokens/keys
- [ ] No sensitive data in logs
- [ ] HTTPS enforced in production

---

## Common Vulnerabilities to Avoid

### SQL Injection
```ruby
# ❌ NEVER
User.where("name = '#{params[:name]}'")

# ✅ ALWAYS
User.where("name = ?", params[:name])
User.where(name: params[:name])
```

### Cross-Site Scripting (XSS)
```erb
<!-- ❌ NEVER -->
<%= raw user_input %>
<%== user_input %>

<!-- ✅ ALWAYS -->
<%= user_input %>  <!-- Escaped by default -->
<%= sanitize user_input, tags: %w[p br] %>  <!-- If HTML needed -->
```

### Mass Assignment
```ruby
# ❌ NEVER
User.create(params[:user])

# ✅ ALWAYS
User.create(user_params)  # With strong parameters
```

### Command Injection
```ruby
# ❌ NEVER
`convert #{params[:file]} output.jpg`
system("rm #{params[:filename]}")

# ✅ ALWAYS
system("convert", params[:file], "output.jpg")  # Array form
```

### Path Traversal
```ruby
# ❌ NEVER
File.read("uploads/#{params[:filename]}")  # Can access ../../../etc/passwd

# ✅ ALWAYS
filename = File.basename(params[:filename])  # Strip directory
path = Rails.root.join('uploads', filename)
File.read(path) if File.exist?(path)
```

---

## Security Tools Integration

### Brakeman
Automatically detects security issues. Don't ignore warnings without documented justification.

```bash
# Run locally
bin/brakeman --quiet

# Configuration
config/brakeman.yml
```

### Bundler Audit
Checks for vulnerable dependencies.

```bash
# Run locally
bin/bundler-audit check

# Configuration  
config/bundler-audit.yml
```

### RuboCop Security
Enforces security best practices.

```bash
# Run locally
bundle exec rubocop --only Security
```

---

## References

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Ruby Security](https://www.ruby-lang.org/en/security/)
- [Brakeman Scanner](https://brakemanscanner.org/)

---

## Summary

When generating code:
1. ✅ Use ENV vars for secrets
2. ✅ Use strong parameters for user input
3. ✅ Parameterize all SQL queries
4. ✅ Validate all user input
5. ✅ Escape/sanitize HTML output
6. ✅ Require authentication for protected endpoints
7. ✅ Check authorization (scope to current user)
8. ✅ Use SecureRandom for tokens
9. ✅ Never log sensitive data
10. ✅ Follow the principle of least privilege

**Security is not optional - it must be built in from the start!**

