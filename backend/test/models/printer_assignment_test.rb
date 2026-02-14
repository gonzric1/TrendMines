require "test_helper"

class PrinterAssignmentTest < ActiveSupport::TestCase
  test "should create valid printer assignment" do
    assignment = PrinterAssignment.new(
      product: products(:frieren_sticker_product),
      printer_name: "Test Printer",
      status: "active"
    )
    assert assignment.valid?
  end

  test "should require printer_name" do
    assignment = PrinterAssignment.new(
      product: products(:frieren_sticker_product),
      status: "active"
    )
    assert_not assignment.valid?
    assert_includes assignment.errors[:printer_name], "can't be blank"
  end

  test "should require status" do
    assignment = PrinterAssignment.new(
      product: products(:frieren_sticker_product),
      printer_name: "Test",
      status: ""
    )
    assert_not assignment.valid?
    assert_includes assignment.errors[:status], "can't be blank"
  end

  test "should belong to product" do
    assignment = printer_assignments(:prusa_mk4_stickers)
    assert_respond_to assignment, :product
    assert_kind_of Product, assignment.product
  end

  test "should have default status of active" do
    assignment = PrinterAssignment.create!(
      product: products(:frieren_sticker_product),
      printer_name: "Test"
    )
    assert_equal "active", assignment.status
  end

  test "should allow valid status values" do
    assignment = printer_assignments(:prusa_mk4_stickers)

    %w[active paused completed].each do |status|
      assignment.status = status
      assert assignment.valid?, "Status #{status} should be valid"
    end
  end

  test "active scope should only return active status" do
    active_assignments = PrinterAssignment.active
    statuses = active_assignments.pluck(:status).uniq
    assert_equal ["active"], statuses
  end
end
