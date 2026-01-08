---
applyTo: 'spec/**/*.rb'
description: 'RSpec testing best practices and code generation guidelines'
---

# RSpec Testing Guidelines

When generating RSpec test code, follow these best practices:

## General Principles

### Use `describe` and `context` Appropriately

```ruby
# Good - Use describe for things, context for states
RSpec.describe User do
  describe '#full_name' do
    context 'when first and last name are present' do
      it 'returns the full name' do
        user = User.new(first_name: 'John', last_name: 'Doe')
        expect(user.full_name).to eq('John Doe')
      end
    end
    
    context 'when last name is missing' do
      it 'returns only the first name' do
        user = User.new(first_name: 'John')
        expect(user.full_name).to eq('John')
      end
    end
  end
end

# Bad - No clear hierarchy
RSpec.describe User do
  it 'returns full name when both names present' do
    # ...
  end
  
  it 'returns first name when last name missing' do
    # ...
  end
end
```

### One Expectation Per Test (When Practical)

```ruby
# Good - Single, focused expectation
it 'validates presence of email' do
  user = User.new(email: nil)
  user.valid?
  expect(user.errors[:email]).to include("can't be blank")
end

# Good - Multiple related expectations for the same behavior
it 'creates a valid user with required attributes' do
  user = User.create(email: 'test@example.com', password: 'password123')
  expect(user).to be_persisted
  expect(user.email).to eq('test@example.com')
end

# Better - Use aggregate_failures for multiple related expectations
it 'creates a valid user with required attributes' do
  user = User.create(email: 'test@example.com', password: 'password123')
  
  aggregate_failures do
    expect(user).to be_persisted
    expect(user.email).to eq('test@example.com')
    expect(user.password).to be_present
  end
end

# Bad - Testing multiple unrelated behaviors
it 'validates user' do
  user = User.new
  expect(user).not_to be_valid
  expect(user.email).to be_nil
  expect(user.created_at).to be_nil
  expect(User.count).to eq(0)
end
```

### Use `let` and `let!` for Test Data

```ruby
# Good - Use let for lazy-loaded test data
describe '#process_order' do
  let(:user) { create(:user) }
  let(:order) { create(:order, user: user, total: 100) }
  
  it 'processes the order successfully' do
    expect(order.process).to be true
  end
end

# Use let! when you need the object to exist before the test runs
describe 'callbacks' do
  let!(:admin) { create(:user, :admin) }
  
  it 'sends notification to all admins' do
    expect(AdminMailer).to receive(:notify).with(admin)
    create(:critical_event)
  end
end

# Bad - Creating objects in each test
it 'processes order' do
  user = create(:user)
  order = create(:order, user: user, total: 100)
  expect(order.process).to be true
end

it 'validates order' do
  user = create(:user)
  order = create(:order, user: user, total: 100)
  expect(order).to be_valid
end
```

### Use `subject` When Testing the Same Object

```ruby
# Good - Explicit subject with name
describe User do
  subject(:user) { described_class.new(email: 'test@example.com') }
  
  it { is_expected.to be_valid }
  
  it 'has the correct email' do
    expect(user.email).to eq('test@example.com')
  end
end

# Good - Implicit subject for one-liners
describe User do
  subject { described_class.new(email: 'test@example.com') }
  
  it { is_expected.to be_valid }
end

# Bad - Recreating object in each test
describe User do
  it 'is valid' do
    user = User.new(email: 'test@example.com')
    expect(user).to be_valid
  end
  
  it 'has correct email' do
    user = User.new(email: 'test@example.com')
    expect(user.email).to eq('test@example.com')
  end
end
```

## Model Specs

### Use Shoulda Matchers for Common Validations

```ruby
# Good - Concise with shoulda-matchers (modern syntax)
RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
  end
  
  describe 'associations' do
    it { is_expected.to have_many(:orders) }
    it { is_expected.to belong_to(:organization) }
  end
end

# Bad - Verbose manual testing
RSpec.describe User, type: :model do
  it 'validates presence of email' do
    user = User.new(email: nil)
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end
  
  it 'validates uniqueness of email' do
    create(:user, email: 'test@example.com')
    user = User.new(email: 'test@example.com')
    expect(user).not_to be_valid
  end
end
```

### Test Business Logic, Not Framework

```ruby
# Good - Test your business logic
describe '#full_name' do
  it 'combines first and last name' do
    user = User.new(first_name: 'John', last_name: 'Doe')
    expect(user.full_name).to eq('John Doe')
  end
end

describe '#active?' do
  context 'when subscription is current' do
    let(:user) { create(:user, subscription_expires_at: 1.day.from_now) }
    
    it 'returns true' do
      expect(user.active?).to be true
    end
  end
end

# Bad - Testing Rails/framework behavior
it 'saves to database' do
  user = User.create(email: 'test@example.com')
  expect(User.find_by(email: 'test@example.com')).to eq(user)
end

it 'has timestamps' do
  user = User.create(email: 'test@example.com')
  expect(user.created_at).not_to be_nil
  expect(user.updated_at).not_to be_nil
end
```

## Request Specs (API/Controller Tests)

### Test the Full Request/Response Cycle

```ruby
# Good - Complete request spec
RSpec.describe 'Api::V1::Users', type: :request do
  describe 'POST /api/v1/users' do
    let(:valid_attributes) do
      {
        user: {
          email: 'test@example.com',
          password: 'password123',
          name: 'John Doe'
        }
      }
    end
    
    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/users', params: valid_attributes
        }.to change(User, :count).by(1)
      end
      
      it 'returns 201 status' do
        post '/api/v1/users', params: valid_attributes
        expect(response).to have_http_status(:created)
      end
      
      it 'returns the user data' do
        post '/api/v1/users', params: valid_attributes
        expect(response.parsed_body['email']).to eq('test@example.com')
        expect(response.parsed_body['name']).to eq('John Doe')
      end
    end
    
    context 'with invalid parameters' do
      let(:invalid_attributes) { { user: { email: '' } } }
      
      it 'does not create a user' do
        expect {
          post '/api/v1/users', params: invalid_attributes
        }.not_to change(User, :count)
      end
      
      it 'returns 422 status' do
        post '/api/v1/users', params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
      end
      
      it 'returns error messages' do
        post '/api/v1/users', params: invalid_attributes
        expect(response.parsed_body['errors']).to be_present
      end
    end
  end
end
```

### Use Shared Examples for Common Behavior

```ruby
# Good - Define shared examples
RSpec.shared_examples 'an authenticated endpoint' do |method, path|
  context 'without authentication' do
    it 'returns 401 unauthorized' do
      send(method, path)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

RSpec.describe 'Api::V1::Budgets', type: :request do
  describe 'GET /api/v1/budgets' do
    it_behaves_like 'an authenticated endpoint', :get, '/api/v1/budgets'
    
    context 'when authenticated' do
      let(:user) { create(:user) }
      let(:headers) { auth_headers(user) }
      
      it 'returns budgets' do
        get '/api/v1/budgets', headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
```

## Factory Best Practices

### Keep Factories Minimal and Valid by Default

```ruby
# Good - Minimal valid factory
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    
    trait :admin do
      role { :admin }
    end
    
    trait :with_orders do
      after(:create) do |user|
        create_list(:order, 3, user: user)
      end
    end
  end
end

# Usage
create(:user)
create(:user, :admin)
create(:user, :with_orders)
create(:user, email: 'specific@example.com')

# Bad - Over-specified factory
FactoryBot.define do
  factory :user do
    email { 'test@example.com' }
    password { 'password123' }
    first_name { 'John' }
    last_name { 'Doe' }
    phone { '555-1234' }
    address { '123 Main St' }
    city { 'Springfield' }
    state { 'IL' }
    zip { '62701' }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
```

### Use Sequences for Unique Attributes

```ruby
# Good - Use sequences for attributes that must be unique
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { 'password123' }
    
    # Optional: Use Faker for realistic non-unique data
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
  end
end

# Bad - Static values that will conflict
FactoryBot.define do
  factory :user do
    email { 'test@example.com' }  # Will fail on second create!
    username { 'testuser' }
  end
end
```

## Test Organization

### Use `before` Hooks Appropriately

```ruby
# Good - Use before for common setup
describe BudgetCalculator do
  let(:user) { create(:user) }
  
  before do
    create(:budget, user: user, amount: 100)
    create(:budget, user: user, amount: 200)
  end
  
  it 'calculates total budget' do
    expect(BudgetCalculator.new(user).total).to eq(300)
  end
end

# Bad - Setup in each test
describe BudgetCalculator do
  it 'calculates total budget' do
    user = create(:user)
    create(:budget, user: user, amount: 100)
    create(:budget, user: user, amount: 200)
    expect(BudgetCalculator.new(user).total).to eq(300)
  end
  
  it 'handles empty budgets' do
    user = create(:user)
    expect(BudgetCalculator.new(user).total).to eq(0)
  end
end
```

## Matcher Preferences

### Use Appropriate Matchers

```ruby
# Good - Use specific matchers
expect(user).to be_valid
expect(user).to be_persisted
expect(user.errors).to be_empty
expect(collection).to be_present
expect(value).to be_nil
expect(user.admin?).to be true

# Bad - Using eq for boolean/nil checks
expect(user.valid?).to eq(true)
expect(user.persisted?).to eq(true)
expect(user.errors.empty?).to eq(true)
expect(value).to eq(nil)
```

### Use `change` for Side Effects

```ruby
# Good - Test side effects with change
expect {
  user.destroy
}.to change(User, :count).by(-1)

expect {
  user.update(email: 'new@example.com')
}.to change { user.reload.email }.from('old@example.com').to('new@example.com')

expect {
  OrderProcessor.new(order).process
}.to change { order.reload.status }.from('pending').to('completed')
  .and change(Invoice, :count).by(1)

# Bad - Not testing the change
user.destroy
expect(User.count).to eq(0)
```

## Test Doubles (Mocks, Stubs, and Spies)

### Use Test Doubles Appropriately

```ruby
# Good - Stub external dependencies
it 'processes payment through gateway' do
  payment_gateway = instance_double(StripeGateway)
  allow(payment_gateway).to receive(:charge).and_return(true)
  
  order = Order.new(payment_gateway: payment_gateway)
  expect(order.process_payment).to be true
end

# Good - Use spies to verify method calls
it 'sends confirmation email after order creation' do
  mailer_spy = spy('OrderMailer')
  allow(OrderMailer).to receive(:confirmation).and_return(mailer_spy)
  
  order.complete!
  
  expect(OrderMailer).to have_received(:confirmation).with(order)
  expect(mailer_spy).to have_received(:deliver_later)
end

# Good - Verify interactions with mocks
it 'logs payment failure' do
  logger = double('Logger')
  expect(logger).to receive(:error).with(/payment failed/i)
  
  order = Order.new(logger: logger)
  order.process_payment_with_invalid_card
end

# Bad - Over-mocking (testing implementation details)
it 'calculates total' do
  order = Order.new
  allow(order).to receive(:subtotal).and_return(100)
  allow(order).to receive(:tax).and_return(10)
  allow(order).to receive(:shipping).and_return(5)
  
  expect(order.total).to eq(115)
end

# Better - Test the real behavior
it 'calculates total from all components' do
  order = Order.new(subtotal: 100, tax_rate: 0.1, shipping: 5)
  expect(order.total).to eq(115)
end
```

### Prefer Dependency Injection for Testability

```ruby
# Good - Injectable dependencies
class OrderProcessor
  def initialize(payment_gateway: StripeGateway.new, notifier: EmailNotifier.new)
    @payment_gateway = payment_gateway
    @notifier = notifier
  end
  
  def process(order)
    if @payment_gateway.charge(order.total)
      @notifier.send_confirmation(order)
      true
    else
      false
    end
  end
end

# In tests
it 'sends confirmation when payment succeeds' do
  gateway = instance_double(StripeGateway, charge: true)
  notifier = spy('EmailNotifier')
  
  processor = OrderProcessor.new(payment_gateway: gateway, notifier: notifier)
  processor.process(order)
  
  expect(notifier).to have_received(:send_confirmation).with(order)
end

# Bad - Hard-coded dependencies
class OrderProcessor
  def process(order)
    if StripeGateway.new.charge(order.total)  # Hard to test
      EmailNotifier.new.send_confirmation(order)
      true
    else
      false
    end
  end
end
```

## Avoid Common Anti-Patterns

```ruby
# Bad - Using sleep in tests
it 'processes after delay' do
  job.perform_later
  sleep 2
  expect(job).to be_processed
end

# Good - Use proper async testing tools
it 'enqueues the job' do
  expect {
    ProcessJob.perform_later
  }.to have_enqueued_job(ProcessJob)
end

# Bad - Testing private methods directly
it 'calculates discount' do
  expect(order.send(:calculate_discount)).to eq(10)
end

# Good - Test through public interface
it 'applies discount to total' do
  order = Order.new(subtotal: 100, discount_code: 'SAVE10')
  expect(order.total).to eq(90)
end

# Bad - Stubbing the method under test
it 'calculates total' do
  allow(order).to receive(:total).and_return(100)
  expect(order.total).to eq(100)
end

# Good - Test the actual method
it 'calculates total from subtotal and tax' do
  order = Order.new(subtotal: 100, tax_rate: 0.1)
  expect(order.total).to eq(110)
end
```

## Naming Conventions

```ruby
# Good - Clear, descriptive test names
describe '#process_payment' do
  context 'when payment is successful' do
    it 'marks the order as paid' do
      # ...
    end
    
    it 'sends a confirmation email' do
      # ...
    end
  end
  
  context 'when payment fails' do
    it 'keeps the order in pending state' do
      # ...
    end
    
    it 'logs the error' do
      # ...
    end
  end
end

# Bad - Vague or redundant names
describe '#process_payment' do
  it 'test payment' do
    # ...
  end
  
  it 'should work' do
    # ...
  end
  
  it 'process_payment processes payment' do
    # ...
  end
end
```

## Use `described_class` for Better Refactoring

```ruby
# Good - Use described_class instead of hardcoding class name
RSpec.describe UserRegistrationService do
  describe '#call' do
    it 'creates a new user' do
      service = described_class.new(user_params)
      expect { service.call }.to change(User, :count).by(1)
    end
  end
end

# Good - Works with nested describes
RSpec.describe Api::V1::UsersController do
  it 'instantiates the controller' do
    controller = described_class.new
    expect(controller).to be_a(described_class)
  end
end

# Bad - Hardcoded class names
RSpec.describe UserRegistrationService do
  describe '#call' do
    it 'creates a new user' do
      service = UserRegistrationService.new(user_params)  # Brittle if class renamed
      expect { service.call }.to change(User, :count).by(1)
    end
  end
end
```

## Summary

When generating RSpec code:
1. Use `describe` for things/methods, `context` for states/conditions
2. Keep tests focused with single expectations when practical
3. Use `aggregate_failures` for multiple related expectations
4. Use `let` and `let!` for test data setup
5. Use `described_class` instead of hardcoding class names
6. Use `is_expected` for shoulda-matchers one-liners (modern syntax)
7. Test behavior, not implementation
8. Use factories over fixtures, keep them minimal
9. Use sequences for unique attributes
10. Use appropriate matchers (`be_valid`, `be_present`, etc.)
11. Test side effects with `change` matcher
12. Use `response.parsed_body` for JSON responses (not `JSON.parse`)
13. Use test doubles (mocks/stubs/spies) for external dependencies
14. Prefer dependency injection for testability
15. Write clear, descriptive test names that explain the behavior
16. Avoid testing private methods, framework behavior, or over-mocking
