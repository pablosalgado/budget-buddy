---
applyTo: '**/*.rb'
description: 'Ruby code generation guidelines following Clean Code and SOLID principles'
---

# Ruby Code Generation Guidelines

## Core Principles

### 1. SOLID Principles

#### Single Responsibility Principle (SRP)
- Each class should have one reason to change
- Keep models focused on domain logic
- Extract complex business logic into service objects or form objects
- Controllers should only handle HTTP concerns

```ruby
# Good: Single responsibility
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  
  has_many :orders
end

class UserRegistrationService
  def initialize(user_params)
    @user_params = user_params
  end
  
  def call
    user = User.new(@user_params)
    user.save ? Result.success(user) : Result.failure(user.errors)
  end
end
```

#### Open/Closed Principle (OCP)
- Classes should be open for extension but closed for modification
- Use inheritance, composition, and modules for extensibility

```ruby
# Good: Use modules for extensibility
module Discountable
  def apply_discount(discount_strategy)
    discount_strategy.apply(self)
  end
end

class Order < ApplicationRecord
  include Discountable
end
```

#### Liskov Substitution Principle (LSP)
- Subtypes must be substitutable for their base types
- Ensure derived classes don't break parent class contracts

#### Interface Segregation Principle (ISP)
- Clients shouldn't depend on interfaces they don't use
- Keep modules and concerns focused and cohesive

```ruby
# Good: Focused concerns
module Searchable
  extend ActiveSupport::Concern
  
  included do
    scope :search, ->(query) { where("name ILIKE ?", "%#{query}%") }
  end
end
```

#### Dependency Inversion Principle (DIP)
- Depend on abstractions, not concretions
- Use dependency injection for flexibility

```ruby
# Good: Dependency injection
class OrderProcessor
  def initialize(payment_gateway: StripeGateway.new, notifier: EmailNotifier.new)
    @payment_gateway = payment_gateway
    @notifier = notifier
  end
  
  def process(order)
    @payment_gateway.charge(order.total)
    @notifier.notify(order.user, order)
  end
end
```

### 2. Clean Code Principles

#### Meaningful Names
- Use intention-revealing names
- Avoid abbreviations and cryptic names
- Use domain language

```ruby
# Bad
def calc_tot(o)
  o.items.sum(&:p)
end

# Good
def calculate_total(order)
  order.items.sum(&:price)
end
```

#### Small Functions/Methods
- Keep methods short (ideally under 10 lines)
- Each method should do one thing well
- Extract complex logic into private methods

```ruby
# Good: Small, focused methods
class Invoice
  def generate
    validate_data
    calculate_totals
    apply_discounts
    format_output
  end
  
  private
  
  def validate_data
    # validation logic
  end
  
  def calculate_totals
    # calculation logic
  end
end
```

#### No Side Effects
- Methods should do what their names suggest
- Avoid hidden mutations
- Make side effects explicit

```ruby
# Bad: Hidden side effect
def user_name
  @user ||= User.find(user_id) # Side effect: database query
  @user.name
end

# Good: Explicit intent
def fetch_user
  @user ||= User.find(user_id)
end

def user_name
  fetch_user.name
end
```

#### DRY (Don't Repeat Yourself)
- Extract repeated logic into methods, concerns, or service objects
- Use Rails helpers and partials for view logic

### 3. Functional-First Programming Approach

**Philosophy**: Prefer functional approaches when they result in clearer, more maintainable code. Use imperative code when it's more readable or appropriate for the context.

#### Prefer Immutability (When It Makes Sense)
- Use `freeze` for constants and configuration values
- Favor creating new objects over mutating when working with data transformations
- Use imperative mutation for performance-critical paths or when building complex objects

```ruby
# Good: Immutable approach for transformations
class PriceCalculator
  DISCOUNT_RATE = 0.1.freeze
  
  def apply_discount(price)
    price * (1 - DISCOUNT_RATE) # Returns new value, original unchanged
  end
end

# Also good: Imperative when building complex objects
class OrderBuilder
  def initialize
    @order = Order.new
    @line_items = []
  end
  
  def add_item(product, quantity)
    @line_items << { product: product, quantity: quantity }
    self # Enable chaining
  end
  
  def build
    @order.line_items = @line_items
    @order
  end
end
```

#### Use Pure Functions for Calculations and Transformations
- Pure functions are ideal for business logic, calculations, and data transformations
- Make dependencies explicit through parameters
- Use instance variables and state when modeling domain objects

```ruby
# Good: Pure function for calculations
def calculate_shipping(weight, distance, rate_per_km)
  base_cost = weight * 0.5
  distance_cost = distance * rate_per_km
  base_cost + distance_cost
end

# Also good: Instance methods for domain behavior
class Order
  def total_price
    line_items.sum(&:total) + shipping_cost + tax
  end
  
  private
  
  def shipping_cost
    calculate_shipping(@weight, @distance, RATE_PER_KM)
  end
end
```

#### Leverage Enumerable Methods (When They're Clearer)
- Use `map`, `select`, `reject`, `reduce` for simple transformations
- Use imperative loops when logic is complex or requires early returns
- Prioritize readability over dogma

```ruby
# Good: Functional approach for simple transformations
def active_user_emails(users)
  users
    .select(&:active?)
    .map(&:email)
    .compact
end

# Also good: Imperative when complex logic is involved
def process_orders(orders)
  results = []
  
  orders.each do |order|
    next if order.cancelled?
    
    if order.needs_review?
      flag_for_review(order)
      next
    end
    
    begin
      results << process_order(order)
    rescue PaymentError => e
      handle_payment_error(order, e)
    end
  end
  
  results
end

# Good: Simple reduce for aggregation
def total_revenue(orders)
  orders.reduce(0) { |sum, order| sum + order.total }
end

# Also good: Imperative when you need to track multiple values
def order_statistics(orders)
  total = 0
  count = 0
  max_order = 0
  
  orders.each do |order|
    total += order.amount
    count += 1
    max_order = [max_order, order.amount].max
  end
  
  { total: total, count: count, average: total / count, max: max_order }
end
```

#### Use Blocks and Lambdas for Flexibility
- Pass behavior as parameters when you need different strategies
- Use simple methods when behavior doesn't vary

```ruby
# Good: Higher-order functions for varying behavior
class ReportGenerator
  def generate(data, formatter: ->(d) { d.to_s })
    processed_data = process(data)
    formatter.call(processed_data)
  end
end

# Also good: Simple methods when behavior is fixed
class InvoiceGenerator
  def generate(order)
    render_template(:invoice, order: order)
  end
end
```

#### Composition vs Mutation: Choose Based on Context
- Use composition for data transformations and when working with external data
- Use mutation for building objects or performance-critical operations

```ruby
# Good: Composition for transformations
def with_premium_features(features)
  features + premium_features
end

# Also good: Mutation when building or modifying owned data
def add_premium_features!(user)
  user.features.concat(premium_features) # Intentional mutation, clear with !
  user.save!
end

# Good: Functional for chaining transformations
def discounted_prices(products, discount_rate)
  products
    .map(&:price)
    .map { |price| price * (1 - discount_rate) }
end

# Also good: Imperative when performance matters
def apply_bulk_discount!(products, discount_rate)
  products.each do |product|
    product.price *= (1 - discount_rate) # Direct mutation for efficiency
  end
end
```

#### Guidelines for Choosing Functional vs Imperative

**Prefer Functional When**:
- Transforming data from one shape to another
- Performing calculations without side effects
- Working with collections in straightforward ways
- Code becomes more declarative and self-documenting

**Prefer Imperative When**:
- Logic involves complex conditionals or early returns
- Building or mutating domain objects intentionally
- Performance is critical (e.g., processing large datasets)
- Code is clearer with explicit steps and state tracking
- Handling errors and edge cases requires complex flow control

### 4. Testing
- Write tests first (TDD) when appropriate
- Keep tests focused and readable
- Use factories (FactoryBot) for test data
- Test behavior, not implementation

> For detailed RSpec testing patterns and examples, see `.github/instructions/rspec.instructions.md`

## Summary

When generating Ruby code:
1. Follow SOLID principles for maintainable code
2. Write clean, self-documenting code
3. Prefer functional approaches when they improve clarity and maintainability
4. Use imperative code when it's clearer or more appropriate for the context
5. Write tests for all business logic
6. Keep methods small and focused
7. Use meaningful names from the domain
8. Choose the right tool (functional vs imperative) based on readability and context
9. Avoid premature optimization
10. Extract repeated logic (DRY principle)
11. Test behavior, not implementation
