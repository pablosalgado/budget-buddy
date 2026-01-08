---
applyTo: '{app,lib,config,db}/**/*.{rb,rake}'
description: 'Rails Development Guidelines for Majestic Monolith'
---

# Rails Development Guidelines

## Core Philosophy

Follow the Majestic Monolith approach: build a well-structured, single Rails application that can scale through simplicity and convention over configuration.

## Architecture Principles

### 1. Keep It in the Monolith
- Default to adding features within the existing Rails app
- Avoid microservices unless absolutely necessary
- Use Rails engines for major feature boundaries if needed
- Leverage Rails' built-in tools: ActiveRecord, ActionCable, ActiveJob, etc.

### 2. Follow Rails Conventions
- Use RESTful routes and standard CRUD operations
- Organize code in app/ following Rails structure: models/, controllers/, views/, jobs/, mailers/
- Prefer "convention over configuration"
- Use Rails generators as starting points

### 3. Domain Organization
- Group related models in concerns when they share behavior
- Use namespaced controllers for admin or API sections
- Keep business logic in models, use service objects sparingly for complex workflows
- Place domain-specific code in lib/ when it doesn't fit standard Rails directories

## Rails Component Guidelines

### Models
- Use ActiveRecord models as the primary data layer
- Add validations, associations, and scopes directly in models
- Use concerns for shared behavior (e.g., `Taggable`, `Searchable`)
- Keep models focused on domain logic, not infrastructure

```ruby
class Product < ApplicationRecord
  include Searchable
  include Taggable
  
  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
  
  scope :available, -> { where(available: true) }
  scope :expensive, -> { where('price > ?', 100) }
  
  def discounted_price(percentage)
    price * (1 - percentage / 100.0)
  end
end
```

### Controllers
- Keep controllers thin - delegate to models or service objects
- Use before_actions for authentication and authorization
- Follow RESTful actions: index, show, new, create, edit, update, destroy
- Use strong parameters for security

```ruby
class OrdersController < ApplicationController
  def create
    result = CreateOrderService.new(order_params, current_user).call
    
    if result.success?
      redirect_to order_path(result.order), notice: 'Order created successfully'
    else
      @order = result.order
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def order_params
    params.require(:order).permit(:product_id, :quantity)
  end
end
```

### Views
- Use ERB templates by default (or Hotwire/Turbo for modern UX)
- Leverage partials for reusability
- Use helpers for view-specific logic
- Keep JavaScript minimal, prefer server-rendered HTML

### Background Jobs
- Use ActiveJob with solid_queue (or sidekiq/resque) for async work
- Keep jobs focused and idempotent
- Use appropriate queue priorities

### Service Objects
- Use for complex business operations
- Return explicit results (success/failure)
- Keep them focused and testable

```ruby
class CreateOrderService
  Result = Struct.new(:success?, :order, :errors, keyword_init: true)
  
  def initialize(order_params, user)
    @order_params = order_params
    @user = user
  end
  
  def call
    order = build_order
    
    if order.save
      process_payment(order)
      send_confirmation(order)
      Result.new(success?: true, order: order, errors: nil)
    else
      Result.new(success?: false, order: order, errors: order.errors)
    end
  end
  
  private
  
  def build_order
    @user.orders.build(@order_params)
  end
  
  def process_payment(order)
    # Payment logic
  end
  
  def send_confirmation(order)
    # Notification logic
  end
end
```

### Form Objects
- Use for complex forms that don't map to a single model
- Keep validation logic in form objects

```ruby
class UserRegistrationForm
  include ActiveModel::Model
  
  attr_accessor :email, :password, :password_confirmation, :accept_terms
  
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }
  validates :password_confirmation, presence: true
  validates :accept_terms, acceptance: true
  validate :passwords_match
  
  def save
    return false unless valid?
    
    user = User.create(email: email, password: password)
    user.persisted?
  end
  
  private
  
  def passwords_match
    errors.add(:password_confirmation, "doesn't match") if password != password_confirmation
  end
end
```

---


## Scaling Within the Monolith

### Performance
- Use caching (fragment, action, Russian doll)
- Add database indexes for frequent queries
- Use ActiveRecord includes/joins to avoid N+1 queries
- Leverage solid_cache for caching layer

### Data
- Start with PostgreSQL for relational data
- Use ActiveStorage for file uploads
- Consider solid_queue for job processing
- Use solid_cache for caching

### Organization
- Use Rails engines for major bounded contexts only when necessary
- Namespace controllers and models for logical separation
- Keep dependencies within the monolith, not across services

## What to Avoid
- Don't create microservices prematurely
- Avoid over-engineering with complex design patterns
- Don't bypass Rails conventions without good reason
- Avoid heavy JavaScript frameworks when server-rendered HTML works
- Don't create service objects for simple CRUD operations

## Key Rails Tools to Leverage
- **Hotwire** (Turbo + Stimulus) for reactive UIs without heavy JS
- **ActionCable** for WebSocket/real-time features
- **ActiveJob** for background processing
- **ActiveStorage** for file uploads
- **ActionMailer** for emails
- **solid_queue**, **solid_cache**, **solid_cable** for infrastructure

## File Organization
```
app/
├── models/           # Domain models and business logic
├── controllers/      # HTTP request handling (MVC web controllers)
│   ├── concerns/    # Shared controller logic
│   └── *_controller.rb  # Web controllers
├── views/           # Templates and UI
├── jobs/            # Background jobs
├── mailers/         # Email templates and logic
├── helpers/         # View helpers
├── javascript/      # Stimulus controllers (minimal JS)
└── assets/          # Stylesheets and images
```

**Note**: For API controllers structure, see `.github/instructions/api.instructions.md`

---

## Development Checklists

### Standard MVC Feature Checklist
- [ ] Model created with validations and associations
- [ ] Database migration created and includes indexes
- [ ] Web controller created with RESTful actions
- [ ] Views created (index, show, new, edit, etc.)
- [ ] Routes added to `config/routes.rb`
- [ ] Strong parameters defined with permitted attributes
- [ ] Controller specs or request specs created and passing
- [ ] Model specs created and passing

**Note**: For API development checklist, see `.github/instructions/api.instructions.md`
