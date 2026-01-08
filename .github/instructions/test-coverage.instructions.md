---
description: 'Test coverage guidelines and best practices'
---

# Test Coverage Guidelines

## Coverage Requirements

- **Minimum Total Coverage**: 85%
- **Minimum File Coverage**: 75%

## Running Coverage

### Local Development

```bash
# Run tests with coverage report
COVERAGE=true bundle exec rspec

# View HTML report in browser
open coverage/index.html
```

### CI/CD

Coverage runs automatically in GitHub Actions with `COVERAGE=true` environment variable. Builds fail if coverage drops below the minimum threshold.

## Coverage Reports

### Console Output

After each test run with coverage enabled:

```
COVERAGE:  92.5% -- 123/133 lines in 12 files

+-------------+-------+--------+--------+--------+
| name        | lines | missed | covered | coverage |
+-------------+-------+--------+--------+--------+
| Models      |    45 |      2 |     43 |   95.56% |
| Controllers |    38 |      5 |     33 |   86.84% |
| Services    |    25 |      0 |     25 |  100.00% |
+-------------+-------+--------+--------+--------+
```

### HTML Report

Open `coverage/index.html` for:
- Line-by-line coverage visualization
- Uncovered code highlighted in red
- Per-file coverage percentages
- Coverage trends over time

## Coverage Best Practices

### What to Test

✅ **Happy paths**: Normal operation flows
✅ **Edge cases**: Boundary conditions, empty inputs, nil values
✅ **Error paths**: Validations, exceptions, failure scenarios
✅ **Business logic**: Complex calculations, algorithms, decisions
✅ **Integration points**: External service interactions, API calls

### What NOT to Focus On

❌ **Configuration files**: Boilerplate, framework setup
❌ **Trivial code**: Simple getters/setters, delegators
❌ **Framework code**: Rails generated methods
❌ **Migrations**: Database schema changes
❌ **Seeds**: Development data scripts

## Writing Effective Tests

### Focus on Behavior

```ruby
# Good: Tests behavior and outcomes
describe '#calculate_total' do
  it 'sums all budget amounts' do
    create(:budget, amount: 100)
    create(:budget, amount: 200)
    
    expect(Budget.total).to eq(300)
  end
end

# Avoid: Tests implementation details
it 'calls sum on amount column' do
  expect(Budget).to receive(:sum).with(:amount)
  Budget.total
end
```

### Test Edge Cases

```ruby
describe '#validate_budget_range' do
  it 'accepts positive budgets' do
    budget = build(:budget, amount: 100)
    expect(budget).to be_valid
  end
  
  it 'rejects negative budgets' do
    budget = build(:budget, amount: -50)
    expect(budget).not_to be_valid
  end
  
  it 'rejects zero budgets' do
    budget = build(:budget, amount: 0)
    expect(budget).not_to be_valid
  end
  
  it 'accepts maximum allowed budget' do
    budget = build(:budget, amount: 1_000_000)
    expect(budget).to be_valid
  end
  
  it 'rejects budgets exceeding maximum' do
    budget = build(:budget, amount: 1_000_001)
    expect(budget).not_to be_valid
  end
end
```

### Test Error Paths

```ruby
describe BudgetService do
  context 'when external service fails' do
    before do
      allow(ExternalAPI).to receive(:call).and_raise(ExternalAPI::Error)
    end
    
    it 'handles the error gracefully' do
      result = BudgetService.call
      expect(result).to be_failure
    end
    
    it 'logs the error' do
      expect(Rails.logger).to receive(:error).with(/External API failed/)
      BudgetService.call
    end
    
    it 'returns appropriate error message' do
      result = BudgetService.call
      expect(result.error).to eq('Unable to connect to external service')
    end
  end
end
```

### Use Contexts for Different Scenarios

```ruby
describe User do
  describe '#active?' do
    context 'when subscription is current' do
      let(:user) { create(:user, subscription_expires_at: 1.day.from_now) }
      
      it 'returns true' do
        expect(user).to be_active
      end
    end
    
    context 'when subscription is expired' do
      let(:user) { create(:user, subscription_expires_at: 1.day.ago) }
      
      it 'returns false' do
        expect(user).not_to be_active
      end
    end
    
    context 'when subscription is nil' do
      let(:user) { create(:user, subscription_expires_at: nil) }
      
      it 'returns false' do
        expect(user).not_to be_active
      end
    end
  end
end
```

## Maintaining Coverage

### Regular Reviews

- Check coverage reports before merging PRs
- Address coverage drops immediately
- Review uncovered critical paths
- Document intentional exclusions

### Addressing Coverage Gaps

If coverage falls below threshold:

1. **Identify uncovered lines** in `coverage/index.html`
2. **Prioritize critical paths** (business logic, security, data integrity)
3. **Write tests** for uncovered code
4. **Document exclusions** if code is intentionally untested

### Excluding Code

Only exclude code when absolutely necessary:

```ruby
# :nocov:
def deprecated_method
  # Legacy code scheduled for removal in v2.0
  # TODO: Remove after migration complete
end
# :nocov:
```

Use sparingly for:
- Deprecated code awaiting removal
- Debug/development-only code
- Code covered by integration tests elsewhere

## Coverage in CI

### GitHub Actions Integration

The CI pipeline:
- ✅ Runs tests with `COVERAGE=true`
- ✅ Fails builds below 90% threshold
- ✅ Uploads coverage reports as artifacts (7-day retention)
- ✅ Shows coverage summary in console output

### Viewing CI Coverage Reports

1. Go to GitHub Actions run
2. Click on "test" job
3. Scroll to "Upload coverage reports" step
4. Download coverage-report artifact
5. Extract and open `index.html`

## Coverage Thresholds

### Total Coverage: 90%

The entire codebase must maintain at least 90% coverage.

**Why 90%?**
- Industry best practice for production applications
- Balances thoroughness with practicality
- Catches most bugs and edge cases
- Allows for some untestable edge cases

### Per-File Coverage: 80%

Individual files must maintain at least 80% coverage.

**Why 80%?**
- Prevents "averaging out" with 100% coverage elsewhere
- Ensures every file has reasonable test coverage
- More forgiving than total threshold for complex files

### Coverage Drop Tolerance: 2%

Coverage can drop by at most 2% from the previous run.

**Why 2%?**
- Prevents gradual coverage degradation
- Allows for minor refactoring
- Requires addressing significant drops immediately

## Troubleshooting

### Coverage Not Running

```bash
# Verify COVERAGE environment variable is set
COVERAGE=true bundle exec rspec

# Check SimpleCov is loaded
grep -r "SimpleCov" spec/
```

### Coverage Below Threshold

```bash
# View detailed report
open coverage/index.html

# Look for red/orange files (low coverage)
# Add tests for uncovered lines

# Re-run tests
COVERAGE=true bundle exec rspec
```

### False Positives

Some code may show as uncovered but is actually tested:
- Inline rescue blocks
- One-line conditionals
- Method aliases

Consider refactoring for better testability or document as intentional exclusion.

## Summary

When writing tests:
1. ✅ Run with `COVERAGE=true` locally
2. ✅ Aim for 100% coverage on new code
3. ✅ Test happy paths, edge cases, and errors
4. ✅ Focus on behavior, not implementation
5. ✅ Review coverage reports before committing
6. ✅ Address coverage drops immediately
7. ✅ Document intentional exclusions
8. ✅ Use coverage as a guide, not a goal

Good coverage is a means to quality, not an end in itself. Write meaningful tests that verify behavior and catch bugs.

