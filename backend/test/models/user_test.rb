require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should create user with valid attributes" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      role: :operator
    )
    assert user.valid?
    assert user.save
  end

  test "should require email" do
    user = User.new(
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      role: :operator
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require name" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :operator
    )
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "should enforce minimum name length" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "A",
      role: :operator
    )
    assert_not user.valid?
    assert_includes user.errors[:name], "is too short (minimum is 2 characters)"
  end

  test "should have operator role by default" do
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    )
    assert user.operator?
  end

  test "should support admin role" do
    user = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Admin User",
      role: :admin
    )
    assert user.admin?
    assert_not user.operator?
  end

  test "should validate email uniqueness" do
    User.create!(
      email: "duplicate@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "First User",
      role: :operator
    )

    duplicate_user = User.new(
      email: "duplicate@example.com",
      password: "password456",
      password_confirmation: "password456",
      name: "Second User",
      role: :operator
    )
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should validate email format" do
    user = User.new(
      email: "invalid-email",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User",
      role: :operator
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "should require password confirmation to match" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "different",
      name: "Test User",
      role: :operator
    )
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end
end
