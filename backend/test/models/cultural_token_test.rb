require "test_helper"

class CulturalTokenTest < ActiveSupport::TestCase
  test "should create valid cultural token" do
    token = CulturalToken.new(
      niche: niches(:frieren_collectors),
      token_type: "quote",
      value: "Test value",
      status: "extracted"
    )
    assert token.valid?
  end

  test "should require token_type" do
    token = CulturalToken.new(
      niche: niches(:frieren_collectors),
      value: "Test",
      status: "extracted"
    )
    assert_not token.valid?
    assert_includes token.errors[:token_type], "can't be blank"
  end

  test "should require value" do
    token = CulturalToken.new(
      niche: niches(:frieren_collectors),
      token_type: "quote",
      status: "extracted"
    )
    assert_not token.valid?
    assert_includes token.errors[:value], "can't be blank"
  end

  test "should require status" do
    token = CulturalToken.new(
      niche: niches(:frieren_collectors),
      token_type: "quote",
      value: "Test",
      status: ""
    )
    assert_not token.valid?
    assert_includes token.errors[:status], "can't be blank"
  end

  test "should belong to niche" do
    token = cultural_tokens(:frieren_quote)
    assert_respond_to token, :niche
    assert_kind_of Niche, token.niche
  end

  test "should have many designs" do
    token = cultural_tokens(:frieren_quote)
    assert_respond_to token, :designs
    assert_kind_of ActiveRecord::Associations::CollectionProxy, token.designs
  end

  test "should destroy associated designs when destroyed" do
    # Create a token with designs that have no products (to avoid foreign key issues)
    token = CulturalToken.create!(
      niche: niches(:archived_niche),
      token_type: "quote",
      value: "Test Token",
      status: "extracted"
    )
    design = Design.create!(
      cultural_token: token,
      design_type: "sticker",
      status: "pending_review"
    )

    assert_difference "Design.count", -1 do
      token.destroy
    end
  end

  test "should have default status of extracted" do
    token = CulturalToken.create!(
      niche: niches(:frieren_collectors),
      token_type: "quote",
      value: "Test"
    )
    assert_equal "extracted", token.status
  end

  test "should allow valid status values" do
    token = cultural_tokens(:frieren_quote)

    %w[extracted designs_pending designs_ready in_production listed].each do |status|
      token.status = status
      assert token.valid?, "Status #{status} should be valid"
    end
  end

  test "by_composite_score scope should order by composite_score descending" do
    tokens = CulturalToken.by_composite_score.to_a
    first_score = tokens.first.composite_score || 0
    last_score = tokens.last.composite_score || 0
    assert first_score >= last_score
  end

  test "ready_for_designs scope should only return extracted status" do
    ready_tokens = CulturalToken.ready_for_designs
    statuses = ready_tokens.pluck(:status).uniq
    assert_equal ["extracted"], statuses
  end
end
