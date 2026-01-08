---
applyTo: 'app/controllers/api/**/*.rb'
description: 'API Development Guidelines for RESTful JSON APIs'
---

# API Development Guidelines

## Core Principles

### RESTful API Design
- Follow RESTful conventions for all endpoints
- Use standard HTTP methods (GET, POST, PATCH/PUT, DELETE)
- Use proper HTTP status codes
- Keep responses consistent and predictable
- Version all APIs from the start
- **Ensure idempotency**: GET, PUT, DELETE should be idempotent (safe to retry)
- **POST creates, PUT/PATCH updates** - use the right verb for the right action

### JSON-First Approach
- All API responses are JSON
- Use `ActionController::API` as base class
- No HTML rendering in API controllers
- Keep API controllers separate from web controllers
- **Always set Content-Type header** to `application/json`

## API Structure

### Versioning
**Always version your APIs** starting with v1:

```ruby
# Namespace structure
namespace :api do
  namespace :v1 do
    resources :budgets
  end
end
```

### File Organization
```
app/
└── controllers/
    └── api/
        └── v1/
            ├── base_controller.rb      # Shared API logic
            ├── budgets_controller.rb   # Resource endpoints
            └── users_controller.rb     # Resource endpoints
```

## Controller Templates

### Base Controller Template

```ruby
# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ActionController::API
      # Error handling
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request
      
      private
      
      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end
      
      def unprocessable_entity(exception)
        render json: { 
          errors: exception.record.errors.full_messages 
        }, status: :unprocessable_entity
      end
      
      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
```

### Resource Controller Template

```ruby
# app/controllers/api/v1/{resource}s_controller.rb
module Api
  module V1
    class {Resource}sController < BaseController
      before_action :set_{resource}, only: [:show, :update, :destroy]
      
      # GET /api/v1/{resources}
      def index
        @{resources} = {Resource}.all
        render json: @{resources}
      end
      
      # GET /api/v1/{resources}/:id
      def show
        render json: @{resource}
      end
      
      # POST /api/v1/{resources}
      def create
        @{resource} = {Resource}.new({resource}_params)
        
        if @{resource}.save
          render json: @{resource}, status: :created, location: api_v1_{resource}_url(@{resource})
        else
          render json: { 
            errors: @{resource}.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end
      
      # PATCH/PUT /api/v1/{resources}/:id
      def update
        if @{resource}.update({resource}_params)
          render json: @{resource}
        else
          render json: { 
            errors: @{resource}.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/{resources}/:id
      def destroy
        @{resource}.destroy
        head :no_content
      end
      
      private
      
      def set_{resource}
        @{resource} = {Resource}.find(params[:id])
        # BaseController handles RecordNotFound errors automatically
      end
      
      def {resource}_params
        params.require(:{resource}).permit(:attr1, :attr2, :attr3)
      end
    end
  end
end
```

## Routing Guidelines

### Standard RESTful Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :budgets      # All 7 RESTful routes
      resources :users        # All 7 RESTful routes
    end
  end
end
```

### Custom Routes

```ruby
namespace :api do
  namespace :v1 do
    resources :budgets do
      member do
        post :archive       # POST /api/v1/budgets/:id/archive
        get :summary        # GET /api/v1/budgets/:id/summary
      end
      
      collection do
        get :search         # GET /api/v1/budgets/search
        get :stats          # GET /api/v1/budgets/stats
      end
    end
  end
end
```

## HTTP Status Codes

Use appropriate HTTP status codes:

### Success Codes
- **200 OK** - Successful GET, PATCH/PUT requests
- **201 Created** - Successful POST request (resource created)
- **204 No Content** - Successful DELETE request

### Client Error Codes
- **400 Bad Request** - Malformed request (e.g., missing required parameter)
- **401 Unauthorized** - Authentication required
- **403 Forbidden** - Authenticated but not authorized
- **404 Not Found** - Resource doesn't exist
- **422 Unprocessable Entity** - Validation errors

### Server Error Codes
- **500 Internal Server Error** - Unexpected server error

## Response Formats

### Success Response (Single Resource)

```ruby
# GET /api/v1/budgets/1
{
  "id": 1,
  "name": "Monthly Budget",
  "amount": 1000.00,
  "category": "personal",
  "created_at": "2026-01-01T00:00:00Z"
}
```

### Success Response (Collection)

```ruby
# GET /api/v1/budgets
[
  {
    "id": 1,
    "name": "Monthly Budget",
    "amount": 1000.00
  },
  {
    "id": 2,
    "name": "Vacation Fund",
    "amount": 500.00
  }
]
```

### Error Response

```ruby
# POST /api/v1/budgets (with invalid data)
{
  "errors": [
    "Name can't be blank",
    "Amount must be greater than 0"
  ]
}
```

## Best Practices

### 1. Controller Organization
- Inherit from `Api::V1::BaseController`
- Use `before_action` for common setup (e.g., `set_resource`)
- Keep actions thin - delegate to models or service objects
- Always use strong parameters

### 2. Error Handling
- Centralize error handling in `BaseController`
- Return consistent error response format
- Use appropriate HTTP status codes
- Include helpful error messages

### 3. Security
- **Always use strong parameters** - never trust user input
- **Validate all inputs** at the model level (presence, format, length, etc.)
- **Sanitize user input** to prevent injection attacks
- **Use authentication** when needed (JWT, API keys, etc.)
- **Implement authorization** - don't expose data users shouldn't see
- **Never expose sensitive data** in responses (passwords, tokens, internal IDs)
- **Use HTTPS only** in production - no plain HTTP for APIs
- Consider rate limiting for production APIs

### 4. Response Optimization
- Only return necessary data (use serializers if needed)
- Implement pagination for large collections
- Use caching when appropriate
- Consider using `jsonapi-serializer` or `blueprinter` for complex responses

### 5. Consistency
- **Use consistent naming** - snake_case for JSON keys (Rails convention)
- **Use consistent response structure** - same format for all endpoints
- **Use consistent error format** - same structure for all errors
- **Use ISO 8601 for timestamps** - `created_at: "2026-01-01T00:00:00Z"`

> **💡 For testing patterns**, see [`.github/instructions/rspec.instructions.md`](rspec.instructions.md) - Request Specs section

## Development Checklist

When creating an API endpoint, ensure:

- [ ] Model created with validations and associations
- [ ] Database migration created with indexes
- [ ] API controller created in `app/controllers/api/v1/`
- [ ] Inherits from `Api::V1::BaseController`
- [ ] Routes added under `namespace :api, namespace :v1`
- [ ] Strong parameters defined
- [ ] All RESTful actions implemented (or only needed ones)
- [ ] Proper HTTP status codes used
- [ ] Error handling implemented
- [ ] Request specs created in `spec/requests/api/v1/`
- [ ] All tests passing (happy paths and errors)

> **💡 For API request spec patterns and examples**, see [`.github/instructions/rspec.instructions.md`](rspec.instructions.md#request-specs-apicontroller-tests)

## Common Patterns

### Authentication

**JWT Authentication** (Recommended for APIs):

```ruby
# Add to Gemfile
gem 'jwt'

# lib/json_web_token.rb
class JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base.to_s

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new decoded
  end
end

# app/controllers/api/v1/base_controller.rb
before_action :authenticate_request

private

def authenticate_request
  header = request.headers['Authorization']
  header = header.split(' ').last if header
  
  begin
    @decoded = JsonWebToken.decode(header)
    @current_user = User.find(@decoded[:user_id])
  rescue ActiveRecord::RecordNotFound, JWT::DecodeError => e
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end

def current_user
  @current_user
end
```

### Pagination

```ruby
def index
  @budgets = Budget.page(params[:page]).per(params[:per_page] || 25)
  
  render json: {
    budgets: @budgets,
    meta: {
      current_page: @budgets.current_page,
      total_pages: @budgets.total_pages,
      total_count: @budgets.total_count
    }
  }
end
```

### Filtering

```ruby
def index
  @budgets = Budget.all
  @budgets = @budgets.where(category: params[:category]) if params[:category]
  @budgets = @budgets.where('amount >= ?', params[:min_amount]) if params[:min_amount]
  
  render json: @budgets
end
```

### Sorting

```ruby
def index
  allowed_sort = %w[name amount created_at]
  sort_by = params[:sort].presence_in(allowed_sort) || 'created_at'
  direction = params[:direction] == 'asc' ? 'asc' : 'desc'
  
  @budgets = Budget.order("#{sort_by} #{direction}")
  render json: @budgets
end
```

### Serializers

Control JSON output and avoid exposing sensitive data:

```ruby
# Add to Gemfile
gem 'blueprinter'

# app/blueprints/budget_blueprint.rb
class BudgetBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :amount, :category, :created_at
  
  association :user, blueprint: UserBlueprint
end

# Usage in controller
def index
  render json: BudgetBlueprint.render(@budgets)
end

def show
  render json: BudgetBlueprint.render(@budget)
end
```

## Summary

When generating API code:
1. Always use versioned namespaces (`Api::V1`)
2. Inherit from `Api::V1::BaseController`
3. Implement proper error handling
4. Use appropriate HTTP status codes
5. Use strong parameters for security
6. Return consistent JSON responses
7. Ensure idempotency (GET, PUT, DELETE are safe to retry)
8. Include Location header in 201 Created responses
9. Validate all inputs at the model level
10. Never expose sensitive data in responses
11. Use consistent naming and response structure
12. Keep controllers focused on HTTP concerns
13. Implement common patterns (pagination, filtering, sorting) as needed

> **For testing API endpoints**, see [`.github/instructions/rspec.instructions.md`](rspec.instructions.md) - comprehensive request spec patterns and best practices
