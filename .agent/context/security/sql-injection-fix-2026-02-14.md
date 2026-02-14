# SQL Injection Vulnerability Fix - 2026-02-14

## Issue: TrendMines-2sl (P0 CRITICAL)

**Status**: ✅ CLOSED
**Commits**:
- `3386673` - Fix SQL injection vulnerability in controller sort parameters
- `30e59a8` - Update test files to use ENV.fetch without fallback

## Vulnerability Description

All API controller index actions were using unsanitized `params[:sort]` directly in ActiveRecord `.order()` calls, allowing arbitrary SQL injection attacks.

### Vulnerable Code Pattern
```ruby
products = products.order(params[:sort] || 'created_at DESC')
```

### Attack Example
```
GET /api/v1/products?sort=id);DROP TABLE products;--
```

This would execute:
```sql
SELECT * FROM products ORDER BY id);DROP TABLE products;--
```

## Solution Implemented

### 1. Centralized Sanitizer Method

Added `sanitize_sort_params` to `BaseController` that:
- **Validates columns** against a whitelist
- **Sanitizes direction** (only ASC/DESC allowed)
- **Returns 400 Bad Request** for invalid parameters
- **Returns nil** on validation failure (early return pattern)

```ruby
def sanitize_sort_params(allowed_columns:, default:)
  return default unless params[:sort].present?

  sort_param = params[:sort].to_s.strip
  parts = sort_param.split(/\s+/)
  column = parts[0]
  direction = parts[1]&.upcase

  # Validate column against whitelist
  unless allowed_columns.include?(column)
    render json: { error: "Invalid sort column. Allowed: #{allowed_columns.join(', ')}" },
           status: :bad_request
    return nil
  end

  # Validate direction (only ASC or DESC allowed)
  if direction.present? && !['ASC', 'DESC'].include?(direction)
    render json: { error: "Invalid sort direction. Use ASC or DESC" },
           status: :bad_request
    return nil
  end

  direction ||= 'ASC'
  "#{column} #{direction}"
end
```

### 2. Updated All 6 Controllers

Each controller now uses the sanitizer with its specific allowed columns:

#### ProductsController
```ruby
sort_order = sanitize_sort_params(
  allowed_columns: %w[id name created_at updated_at product_type status unit_cost target_price margin_pct],
  default: 'created_at DESC'
)
return unless sort_order

products = products.order(sort_order)
```

#### NichesController
```ruby
sort_order = sanitize_sort_params(
  allowed_columns: %w[id name status demand_score supply_score demand_supply_ratio ao3_works_count ao3_growth_rate etsy_listing_count created_at updated_at discovered_at],
  default: 'demand_supply_ratio DESC'
)
```

#### TrendSignalsController
```ruby
sort_order = sanitize_sort_params(
  allowed_columns: %w[id source topic status momentum_score first_seen last_updated created_at updated_at],
  default: 'momentum_score DESC'
)
```

#### DesignsController
```ruby
sort_order = sanitize_sort_params(
  allowed_columns: %w[id design_type status style generation_cost created_at updated_at],
  default: 'created_at DESC'
)
```

#### CulturalTokensController
```ruby
sort_order = sanitize_sort_params(
  allowed_columns: %w[id token_type value status frequency_score emotional_intensity visual_potential uniqueness_score composite_score created_at updated_at],
  default: 'composite_score DESC'
)
```

#### ListingsController
```ruby
sort_order = sanitize_sort_params(
  allowed_columns: %w[id title status price listed_at created_at updated_at],
  default: 'listed_at DESC'
)
```

### 3. Comprehensive Test Coverage

Added 15 new security tests across 3 test files:

#### ProductsControllerTest (9 tests)
- ✅ Valid sort with ASC
- ✅ Valid sort with DESC
- ✅ Valid sort without direction
- ✅ Reject invalid column
- ✅ Reject SQL injection in column (DROP TABLE)
- ✅ Reject invalid direction
- ✅ Reject SQL injection in direction
- ✅ Reject UNION injection
- ✅ Default sort when empty

#### NichesControllerTest (3 tests)
- ✅ Valid sort on demand_supply_ratio
- ✅ Reject SQL injection attempt
- ✅ Reject invalid column

#### BaseControllerTest (8 tests)
- ✅ Default when blank
- ✅ Accept valid ASC
- ✅ Accept valid DESC
- ✅ Reject invalid column
- ✅ Reject invalid direction
- ✅ Block DROP TABLE injection
- ✅ Block UNION injection
- ✅ Block semicolon injection

## Test Results

```
Running 168 tests in parallel using 16 processes
168 runs, 381 assertions, 0 failures, 0 errors, 1 skips
```

All tests pass! ✅

## Security Impact

### Before
- **6 vulnerable endpoints** allowing SQL injection
- **Zero validation** on sort parameters
- **Critical risk**: Data loss, unauthorized access, system compromise

### After
- **100% of controllers** protected with whitelisting
- **Strict validation** on column names and sort direction
- **400 Bad Request** response for all injection attempts
- **Comprehensive test coverage** to prevent regression

## Files Changed

### Implementation (7 files)
- `backend/app/controllers/api/v1/base_controller.rb` (+41 lines)
- `backend/app/controllers/api/v1/products_controller.rb` (+10 lines)
- `backend/app/controllers/api/v1/niches_controller.rb` (+10 lines)
- `backend/app/controllers/api/v1/trend_signals_controller.rb` (+10 lines)
- `backend/app/controllers/api/v1/designs_controller.rb` (+10 lines)
- `backend/app/controllers/api/v1/cultural_tokens_controller.rb` (+10 lines)
- `backend/app/controllers/api/v1/listings_controller.rb` (+10 lines)

### Tests (4 files)
- `backend/test/controllers/api/v1/base_controller_test.rb` (+50 lines)
- `backend/test/controllers/api/v1/products_controller_test.rb` (+62 lines)
- `backend/test/controllers/api/v1/niches_controller_test.rb` (+19 lines)
- `backend/test/test_helper.rb` (+1 line)

**Total**: 11 files, +225 insertions, -19 deletions

## Related Issues

This fix blocks the parent task:
- **TrendMines-ct0**: Create Rails API backend with SQLite (P2)

## Lessons Learned

1. **Never trust user input** - Always validate and sanitize parameters before SQL operations
2. **Centralize security logic** - Shared sanitizer method ensures consistency
3. **Whitelist > Blacklist** - Column whitelisting is more secure than trying to block malicious patterns
4. **Test injection attempts** - Security tests should explicitly verify attack scenarios are blocked
5. **Early return pattern** - Return nil from sanitizer allows controllers to exit cleanly on validation failure

## References

- [OWASP SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html#sql-injection)
- Task: TrendMines-2sl
