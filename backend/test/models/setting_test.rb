require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "should create valid setting" do
    setting = Setting.new(
      key: "scanning.new_source",
      value: 24,
      category: "scanning",
      description: "Test setting"
    )
    assert setting.valid?
  end

  test "should require key" do
    setting = Setting.new(category: "scanning", value: 1)
    assert_not setting.valid?
    assert_includes setting.errors[:key], "can't be blank"
  end

  test "should require unique key" do
    existing = settings(:ao3_frequency)
    setting = Setting.new(
      key: existing.key,
      value: 24,
      category: "scanning"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:key], "has already been taken"
  end

  test "should require category" do
    setting = Setting.new(key: "test.key", value: 1)
    assert_not setting.valid?
    assert_includes setting.errors[:category], "can't be blank"
  end

  test "should require valid category" do
    setting = Setting.new(key: "test.key", value: 1, category: "invalid")
    assert_not setting.valid?
    assert_includes setting.errors[:category], "is not included in the list"
  end

  test "should allow all valid categories" do
    Setting::CATEGORIES.each do |cat|
      setting = Setting.new(key: "#{cat}.test_key", value: cat == "scanning" ? 1 : "test", category: cat)
      setting.valid?
      assert_not_includes setting.errors[:category], "is not included in the list",
        "Category '#{cat}' should be valid"
    end
  end

  test "scanning values must be positive integers" do
    setting = settings(:ao3_frequency)

    setting.value = 0
    assert_not setting.valid?

    setting.value = -1
    assert_not setting.valid?

    setting.value = 1.5
    assert_not setting.valid?

    setting.value = 12
    assert setting.valid?
  end

  test "scoring weights must be integers between 1 and 10" do
    setting = settings(:momentum_weight)

    setting.value = 0
    assert_not setting.valid?

    setting.value = 11
    assert_not setting.valid?

    setting.value = 5
    assert setting.valid?
  end

  test "scoring thresholds must be between 0 and 1" do
    setting = settings(:viability_threshold)

    setting.value = -0.1
    assert_not setting.valid?

    setting.value = 1.1
    assert_not setting.valid?

    setting.value = 0.7
    assert setting.valid?
  end

  test "alert thresholds must be between 0 and 1" do
    setting = settings(:sales_drop_threshold)

    setting.value = -0.1
    assert_not setting.valid?

    setting.value = 1.1
    assert_not setting.valid?

    setting.value = 0.5
    assert setting.valid?
  end

  test "by_category scope filters correctly" do
    scanning = Setting.by_category("scanning")
    scanning.each do |s|
      assert_equal "scanning", s.category
    end
  end

  test "grouped_by_category returns hash of arrays" do
    grouped = Setting.grouped_by_category
    assert_kind_of Hash, grouped
    grouped.each do |category, settings_list|
      assert_includes Setting::CATEGORIES, category
      settings_list.each { |s| assert_equal category, s.category }
    end
  end

  test "allows nil value" do
    setting = Setting.new(
      key: "templates.new_template",
      value: nil,
      category: "templates",
      description: "A template"
    )
    assert setting.valid?
  end

  test "integrations category allows string values" do
    setting = settings(:webhook_url)
    assert setting.valid?
  end
end
