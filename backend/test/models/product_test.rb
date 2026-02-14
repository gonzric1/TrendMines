require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "should create valid product" do
    product = Product.new(
      design: designs(:frieren_sticker),
      product_type: "vinyl_sticker",
      name: "Test Product",
      status: "prototype"
    )
    assert product.valid?
  end

  test "should require product_type" do
    product = Product.new(
      design: designs(:frieren_sticker),
      name: "Test",
      status: "prototype"
    )
    assert_not product.valid?
    assert_includes product.errors[:product_type], "can't be blank"
  end

  test "should require name" do
    product = Product.new(
      design: designs(:frieren_sticker),
      product_type: "sticker",
      status: "prototype"
    )
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "should require status" do
    product = Product.new(
      design: designs(:frieren_sticker),
      product_type: "sticker",
      name: "Test",
      status: ""
    )
    assert_not product.valid?
    assert_includes product.errors[:status], "can't be blank"
  end

  test "should belong to design" do
    product = products(:frieren_sticker_product)
    assert_respond_to product, :design
    assert_kind_of Design, product.design
  end

  test "should have many listings" do
    product = products(:frieren_sticker_product)
    assert_respond_to product, :listings
    assert_kind_of ActiveRecord::Associations::CollectionProxy, product.listings
  end

  test "should have many printer assignments" do
    product = products(:frieren_sticker_product)
    assert_respond_to product, :printer_assignments
    assert_kind_of ActiveRecord::Associations::CollectionProxy, product.printer_assignments
  end

  test "should destroy associated listings when destroyed" do
    product = products(:frieren_sticker_product)
    listing_count = product.listings.count
    assert listing_count > 0, "Product should have listings for this test"

    assert_difference "Listing.count", -listing_count do
      product.destroy
    end
  end

  test "should destroy associated printer assignments when destroyed" do
    product = products(:frieren_sticker_product)
    assignment_count = product.printer_assignments.count
    assert assignment_count > 0, "Product should have assignments for this test"

    assert_difference "PrinterAssignment.count", -assignment_count do
      product.destroy
    end
  end

  test "should have default status of prototype" do
    product = Product.create!(
      design: designs(:frieren_sticker),
      product_type: "sticker",
      name: "Test"
    )
    assert_equal "prototype", product.status
  end

  test "should allow valid status values" do
    product = products(:frieren_sticker_product)

    %w[prototype listed scaling declining retired].each do |status|
      product.status = status
      assert product.valid?, "Status #{status} should be valid"
    end
  end

  test "active scope should only return listed and scaling products" do
    active_products = Product.active
    statuses = active_products.pluck(:status).uniq

    %w[listed scaling].each do |status|
      assert_includes statuses, status
    end
    assert_not_includes statuses, "retired"
  end
end
