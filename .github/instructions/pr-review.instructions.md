---
description: 'GitHub Copilot PR review guidelines for automated code review'
---

# Pull Request Review Guidelines

When reviewing pull requests, systematically check for these common issues and anti-patterns. This guide helps maintain code quality, security, and performance standards.

## About This Guide

This PR review checklist is a **quick reference** for the most critical issues to catch during code review. For comprehensive guidelines on specific topics, refer to:

- **Security Details**: [security.instructions.md](security.instructions.md) - Comprehensive security practices
- **Rails Patterns**: [rails.instructions.md](rails.instructions.md) - MVC architecture and Majestic Monolith
- **API Standards**: [api.instructions.md](api.instructions.md) - RESTful API development
- **Ruby Best Practices**: [ruby.instructions.md](ruby.instructions.md) - SOLID principles and clean code
- **Testing Patterns**: [rspec.instructions.md](rspec.instructions.md) - RSpec testing best practices
- **Coverage Requirements**: [test-coverage.instructions.md](test-coverage.instructions.md) - Coverage thresholds
- **Commit Format**: [../git-commit-instructions.md](../git-commit-instructions.md) - Conventional commits

This guide focuses on **what to look for during PR review** rather than duplicating implementation details covered in the other files.

---

## 🚨 Critical Issues (Must Block Merge)

### Security Vulnerabilities

> **📚 For comprehensive security guidelines and examples**, see [`.github/instructions/security.instructions.md`](security.instructions.md)

**Quick checklist - ensure PR does NOT contain:**
- [ ] Hardcoded secrets, API keys, or credentials
- [ ] SQL injection vulnerabilities (string interpolation in queries)
- [ ] Missing strong parameters in controllers
- [ ] XSS vulnerabilities (raw/html_safe without sanitization)
- [ ] Missing authentication on protected endpoints
- [ ] Missing authorization checks (scoping to current_user)
- [ ] Insecure random generation (using `rand` instead of `SecureRandom`)
- [ ] Sensitive data in logs or error messages

**Example checks:**
```ruby
# ❌ CRITICAL - Hardcoded secret
API_KEY = "sk_live_abc123"

# ❌ CRITICAL - SQL injection
User.where("email = '#{params[:email]}'")

# ❌ CRITICAL - Missing strong parameters
@user.update(params[:user])

# ❌ CRITICAL - Missing authorization
@budget = Budget.find(params[:id])  # Any user can access any budget!
```

### Performance Problems

#### N+1 Queries
```ruby
# ❌ BAD - N+1 query
@users = User.all
@users.each do |user|
  puts user.posts.count  # Triggers query per user
  puts user.profile.name # Triggers query per user
end

# ✅ GOOD - Eager loading
@users = User.includes(:posts, :profile)
@users.each do |user|
  puts user.posts.count
  puts user.profile.name
end
```

```ruby
# ❌ BAD - N+1 in views
@posts.each do |post|
  <%= post.author.name %>  # N+1 if not preloaded
  <%= post.comments.count %> # N+1 if not preloaded
end

# ✅ GOOD - Preload in controller
@posts = Post.includes(:author).with_attached_comments_count
```

#### Missing Database Indexes
```ruby
# ❌ BAD - Foreign keys without indexes
create_table :posts do |t|
  t.references :user, null: false  # Missing index!
  t.string :status
  t.timestamps
end

# ✅ GOOD - Proper indexes
create_table :posts do |t|
  t.references :user, null: false, foreign_key: true, index: true
  t.string :status
  t.timestamps
  
  t.index :status
  t.index [:user_id, :status]
  t.index :created_at
end
```

#### Queries in Loops
```ruby
# ❌ BAD - Database query per iteration
user_ids.each do |id|
  user = User.find(id)
  process_user(user)
end

# ✅ GOOD - Single query
users = User.where(id: user_ids)
users.each do |user|
  process_user(user)
end
```

#### Missing Pagination
```ruby
# ❌ BAD - Loading all records
@posts = Post.all
@users = current_user.followers

# ✅ GOOD - Paginated results
@posts = Post.page(params[:page]).per(25)
@users = current_user.followers.page(params[:page])
```

#### Inefficient Counter Updates
```ruby
# ❌ BAD - Loading record just to increment
post = Post.find(params[:id])
post.views_count += 1
post.save

# ✅ GOOD - Direct database update
Post.increment_counter(:views_count, params[:id])
```

## ⚠️ Important Issues (Should Fix Before Merge)

### Code Quality

#### Missing Model Validations
```ruby
# ❌ BAD - No validations
class User < ApplicationRecord
  has_many :posts
end

# ✅ GOOD - Appropriate validations
class User < ApplicationRecord
  has_many :posts
  
  validates :email, presence: true, 
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, 
                       uniqueness: true,
                       length: { minimum: 3, maximum: 50 }
  validates :age, numericality: { greater_than: 0 }, allow_nil: true
end
```

#### Missing Error Handling
```ruby
# ❌ BAD - No error handling
def create
  @post = current_user.posts.create!(post_params)
  redirect_to @post
end

# ✅ GOOD - Proper error handling
def create
  @post = current_user.posts.build(post_params)
  
  if @post.save
    redirect_to @post, notice: "Post created successfully"
  else
    render :new, status: :unprocessable_entity
  end
end
```

#### Methods Too Long
```ruby
# ❌ BAD - Method doing too much (> 15 lines)
def process_order
  # 50 lines of mixed concerns
  # validation, calculation, notification, logging, etc.
end

# ✅ GOOD - Single responsibility, small methods
def process_order
  validate_order!
  calculate_total
  charge_payment
  send_confirmation
  log_transaction
end

private

def validate_order
  # 3-5 lines
end

def calculate_total
  # 3-5 lines
end
```

#### Single Responsibility & Code Organization

> **📚 For SOLID principles**, see [`.github/instructions/ruby.instructions.md`](ruby.instructions.md)  
> **📚 For Rails architecture patterns**, see [`.github/instructions/rails.instructions.md`](rails.instructions.md)

**Check for:**
- [ ] Controllers doing business logic (extract to services)
- [ ] Methods longer than 15 lines
- [ ] Classes with multiple responsibilities
- [ ] Missing service objects for complex workflows

```ruby
# ❌ BAD - Controller doing too much
class OrdersController < ApplicationController
  def create
    @order = Order.new(order_params)
    @order.total = calculate_tax_and_shipping(@order)
    send_email_to_customer
    notify_warehouse
    update_inventory
    # ... 40+ lines of business logic
  end
end

# ✅ GOOD - Extracted to service
class OrdersController < ApplicationController
  def create
    result = Orders::CreateService.new(order_params, current_user).call
    # Controller only handles HTTP concerns
  end
end
```

#### Missing Null Checks
```ruby
# ❌ BAD - Potential nil errors
def full_name
  "#{user.first_name} #{user.last_name}"
end

# ✅ GOOD - Safe navigation or presence checks
def full_name
  return unless user
  [user.first_name, user.last_name].compact.join(" ").presence || "Anonymous"
end
```

### API-Specific Issues

> **📚 For complete API guidelines**, see [`.github/instructions/api.instructions.md`](api.instructions.md)

**Check for:**
- [ ] Missing or incorrect HTTP status codes
- [ ] Inconsistent error response format
- [ ] Missing API versioning (should be under `Api::V1`)
- [ ] Exposing sensitive data in responses
- [ ] Not using `Api::V1::BaseController`

```ruby
# ❌ BAD - Wrong status, no versioning
class Api::UsersController < ApplicationController
  def create
    @user = User.create(user_params)
    render json: @user  # Exposes all attributes, wrong status
  end
end

# ✅ GOOD - Proper API structure
class Api::V1::UsersController < Api::V1::BaseController
  def create
    @user = User.new(user_params)
    if @user.save
      render json: UserSerializer.new(@user), status: :created
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end
end
```

### Testing Issues

> **📚 For comprehensive testing patterns**, see [`.github/instructions/rspec.instructions.md`](rspec.instructions.md)  
> **📚 For coverage requirements**, see [`.github/instructions/test-coverage.instructions.md`](test-coverage.instructions.md)

#### Missing Test Coverage for New Code
```ruby
# When adding a new method:
class User < ApplicationRecord
  def full_name
    "#{first_name} #{last_name}"
  end
end

# ✅ MUST have corresponding test
RSpec.describe User, type: :model do
  describe "#full_name" do
    it "returns the combined first and last name" do
      user = User.new(first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end
  end
end
```

#### Testing Implementation Instead of Behavior
```ruby
# ❌ BAD - Testing implementation details
it "calls UserMailer.welcome_email" do
  expect(UserMailer).to receive(:welcome_email)
  service.call
end

# ✅ GOOD - Testing behavior/outcome
it "sends a welcome email to the user" do
  expect { service.call }.to change { ActionMailer::Base.deliveries.count }.by(1)
end
```

> **See rspec.instructions.md** for comprehensive testing patterns

#### Missing Edge Cases
```ruby
# ✅ GOOD - Test happy path AND edge cases
describe "#divide" do
  it "divides two numbers" do
    expect(calculator.divide(10, 2)).to eq(5)
  end
  
  it "handles division by zero" do
    expect { calculator.divide(10, 0) }.to raise_error(ZeroDivisionError)
  end
  
  it "handles nil values" do
    expect(calculator.divide(nil, 2)).to be_nil
  end
end
```

> **See rspec.instructions.md** for edge case testing patterns

#### Coverage Drop > 2%
- New code should maintain or increase coverage (min 85% total, 75% per file)
- Coverage drops > 2% require justification
- Check SimpleCov report: `coverage/index.html`

> **See test-coverage.instructions.md** for detailed coverage guidelines

## 💡 Suggestions (Nice to Have)

### Rails Conventions

> **📚 For Rails patterns and Majestic Monolith approach**, see [`.github/instructions/rails.instructions.md`](rails.instructions.md)

#### Non-RESTful Routes
```ruby
# ⚠️ CONSIDER - Custom actions
resources :posts do
  post :publish
  post :archive
end

# 💡 BETTER - RESTful nested resource
resources :posts do
  resource :publication, only: [:create, :destroy]
  resource :archive, only: [:create, :destroy]
end
```

#### Missing Scopes
```ruby
# ⚠️ CONSIDER - Repeated query logic
Post.where(published: true).where("created_at > ?", 1.week.ago)

# 💡 BETTER - Defined scopes
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { where("created_at > ?", 1.week.ago) }
end

Post.published.recent
```

### Code Style

#### Unclear Variable Names
```ruby
# ⚠️ CONSIDER - Unclear names
def calc(a, b, c)
  result = a * b + c
  data.map { |x| x.process(result) }
end

# 💡 BETTER - Descriptive names
def calculate_total_price(base_price, quantity, shipping_cost)
  subtotal = base_price * quantity + shipping_cost
  line_items.map { |item| item.apply_price(subtotal) }
end
```

#### Magic Numbers
```ruby
# ⚠️ CONSIDER - Magic numbers
if user.age < 18
  # minor logic
elsif user.age >= 65
  # senior logic
end

# 💡 BETTER - Named constants
class User
  MINOR_AGE_THRESHOLD = 18
  SENIOR_AGE_THRESHOLD = 65
  
  def minor?
    age < MINOR_AGE_THRESHOLD
  end
  
  def senior?
    age >= SENIOR_AGE_THRESHOLD
  end
end
```

#### Missing Documentation for Complex Logic
```ruby
# ⚠️ CONSIDER - Complex algorithm without explanation
def calculate_score
  (base * 0.6 + bonus * 0.3 + streak * 0.1) * multiplier
end

# 💡 BETTER - Documented logic
# Calculates user engagement score using weighted formula:
# - Base actions: 60% weight (likes, comments, shares)
# - Bonus actions: 30% weight (quality contributions)
# - Streak bonus: 10% weight (consecutive days active)
# Multiplier applied for premium users (1.5x) or penalties (0.5x)
def calculate_engagement_score
  weighted_base = base_actions_score * BASE_WEIGHT
  weighted_bonus = bonus_actions_score * BONUS_WEIGHT
  weighted_streak = streak_score * STREAK_WEIGHT
  
  (weighted_base + weighted_bonus + weighted_streak) * user_multiplier
end
```

## 📋 Review Checklist

Use this checklist when reviewing PRs:

### Security ✓
- [ ] No hardcoded secrets or credentials
- [ ] All user input is validated and sanitized
- [ ] Strong parameters used for mass assignment
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] Authentication/authorization checks present
- [ ] Secure random generation for tokens

### Performance ✓
- [ ] No N+1 queries (check with bullet gem)
- [ ] Appropriate indexes on database columns
- [ ] No queries inside loops
- [ ] Pagination used for large collections
- [ ] Counter caches used where appropriate
- [ ] Background jobs for slow operations

### Code Quality ✓
- [ ] Single Responsibility Principle followed
- [ ] Methods are < 15 lines
- [ ] Classes are focused and cohesive
- [ ] Appropriate validations on models
- [ ] Error handling present
- [ ] Null/edge cases handled
- [ ] DRY - no unnecessary duplication

### Testing ✓
- [ ] New code has test coverage
- [ ] Tests focus on behavior, not implementation
- [ ] Edge cases are tested
- [ ] Test descriptions are clear (RSpec contexts)
- [ ] Coverage has not dropped > 2%
- [ ] Tests are not flaky

### Rails Conventions ✓
- [ ] RESTful routes preferred
- [ ] Controllers are thin
- [ ] Business logic in models/services
- [ ] Migrations are reversible
- [ ] Database constraints match model validations

### API (if applicable) ✓
- [ ] Proper HTTP status codes
- [ ] Consistent error response format
- [ ] API versioning used
- [ ] Serializers hide sensitive data
- [ ] Rate limiting considered
- [ ] Documentation updated

### Documentation ✓
- [ ] Complex logic is commented
- [ ] README updated if needed
- [ ] API docs updated if needed
- [ ] Commit messages follow conventional format (see [git-commit-instructions.md](../git-commit-instructions.md))

## 🔍 How to Check for Common Issues

### Check for N+1 Queries
1. Look for associations accessed in loops/views
2. Run tests with Bullet gem enabled
3. Check for missing `includes`, `preload`, or `eager_load`

### Check for Missing Indexes
1. Review migrations for foreign keys
2. Look for columns used in WHERE clauses
3. Check for columns used in ORDER BY
4. Verify composite indexes for multi-column queries

### Check for Security Issues
1. Search for `where("` - check for string interpolation
2. Search for `.html_safe` and `raw` - verify sanitization
3. Search for `ENV[` - check for fallback values
4. Review strong parameters in controllers
5. Check authentication filters on sensitive actions

### Check Test Coverage
1. Run `bundle exec rspec` locally
2. Check SimpleCov report in `coverage/index.html`
3. Verify new files/methods are tested
4. Check overall coverage percentage

## 🎯 Priority Levels

**P0 - Block Merge Immediately:**
- Security vulnerabilities
- N+1 queries that will cause production issues
- Missing critical validations
- Exposed secrets

**P1 - Must Fix Before Merge:**
- Missing error handling
- Performance issues
- Broken tests
- Coverage drop > 2%

**P2 - Should Fix:**
- Code quality issues
- Missing edge case tests
- Convention violations
- Minor refactoring opportunities

**P3 - Nice to Have:**
- Style improvements
- Additional documentation
- Potential future optimizations

## 🤖 Automated Checks

These should be caught by CI before manual review:
- RuboCop linting
- Brakeman security scanning
- Bundle Audit for vulnerable dependencies
- RSpec test suite passing
- SimpleCov coverage threshold

Focus manual review on logic, architecture, and issues that automated tools can't catch.

