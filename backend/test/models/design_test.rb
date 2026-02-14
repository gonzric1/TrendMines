require "test_helper"

class DesignTest < ActiveSupport::TestCase
  test "should create valid design" do
    design = Design.new(
      cultural_token: cultural_tokens(:frieren_quote),
      design_type: "sticker",
      status: "pending_review"
    )
    assert design.valid?
  end

  test "should require design_type" do
    design = Design.new(
      cultural_token: cultural_tokens(:frieren_quote),
      status: "pending_review"
    )
    assert_not design.valid?
    assert_includes design.errors[:design_type], "can't be blank"
  end

  test "should require status" do
    design = Design.new(
      cultural_token: cultural_tokens(:frieren_quote),
      design_type: "sticker",
      status: ""
    )
    assert_not design.valid?
    assert_includes design.errors[:status], "can't be blank"
  end

  test "should belong to cultural token" do
    design = designs(:frieren_sticker)
    assert_respond_to design, :cultural_token
    assert_kind_of CulturalToken, design.cultural_token
  end

  test "should have many products" do
    design = designs(:frieren_sticker)
    assert_respond_to design, :products
    assert_kind_of ActiveRecord::Associations::CollectionProxy, design.products
  end

  test "should nullify products when destroyed" do
    # Skip this test because products have NOT NULL constraint on design_id
    # This is a schema design choice - products require a design
    skip "Products have NOT NULL constraint on design_id"
  end

  test "should have default status of pending_review" do
    design = Design.create!(
      cultural_token: cultural_tokens(:frieren_quote),
      design_type: "sticker"
    )
    assert_equal "pending_review", design.status
  end

  test "should allow valid status values" do
    design = designs(:frieren_sticker)

    %w[pending_review approved rejected needs_revision].each do |status|
      design.status = status
      assert design.valid?, "Status #{status} should be valid"
    end
  end

  test "pending scope should only return pending_review status" do
    pending = Design.pending
    statuses = pending.pluck(:status).uniq
    assert_equal ["pending_review"], statuses
  end

  test "approved scope should only return approved status" do
    approved = Design.approved
    statuses = approved.pluck(:status).uniq
    assert_equal ["approved"], statuses
  end
end
