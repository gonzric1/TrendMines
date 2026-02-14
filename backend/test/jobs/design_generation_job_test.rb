require "test_helper"

class DesignGenerationJobTest < ActiveJob::TestCase
  setup do
    @token = cultural_tokens(:bg3_character)
  end

  test "enqueues job successfully" do
    assert_enqueued_with(job: DesignGenerationJob) do
      DesignGenerationJob.perform_later(cultural_token_ids: [@token.id])
    end
  end

  test "calls pipeline for each token id" do
    call_count = 0
    mock_new = proc do |cultural_token_id:, template_id:|
      call_count += 1
      mock = Minitest::Mock.new
      mock.expect(:call, { designs: [], total_cost: 0.0 })
      mock
    end

    Designs::GenerationPipeline.stub(:new, mock_new) do
      DesignGenerationJob.perform_now(cultural_token_ids: [@token.id])
    end

    assert_equal 1, call_count
  end

  test "handles batch of multiple token ids" do
    token_ids_received = []
    mock_new = proc do |cultural_token_id:, template_id:|
      token_ids_received << cultural_token_id
      mock = Minitest::Mock.new
      mock.expect(:call, { designs: [], total_cost: 0.0 })
      mock
    end

    token1 = cultural_tokens(:bg3_character)
    token2 = cultural_tokens(:stranger_things_token)

    Designs::GenerationPipeline.stub(:new, mock_new) do
      DesignGenerationJob.perform_now(cultural_token_ids: [token1.id, token2.id])
    end

    assert_includes token_ids_received, token1.id
    assert_includes token_ids_received, token2.id
  end

  test "passes template_id to pipeline" do
    received_template_id = nil
    mock_new = proc do |cultural_token_id:, template_id:|
      received_template_id = template_id
      mock = Minitest::Mock.new
      mock.expect(:call, { designs: [], total_cost: 0.0 })
      mock
    end

    Designs::GenerationPipeline.stub(:new, mock_new) do
      DesignGenerationJob.perform_now(
        cultural_token_ids: [@token.id],
        template_id: 42
      )
    end

    assert_equal 42, received_template_id
  end

  test "discards on ActiveRecord::RecordNotFound" do
    assert_nothing_raised do
      DesignGenerationJob.perform_now(cultural_token_ids: [-999])
    end
  end

  test "handles single token id wrapped in array" do
    call_count = 0
    mock_new = proc do |cultural_token_id:, template_id:|
      call_count += 1
      mock = Minitest::Mock.new
      mock.expect(:call, { designs: [], total_cost: 0.0 })
      mock
    end

    Designs::GenerationPipeline.stub(:new, mock_new) do
      DesignGenerationJob.perform_now(cultural_token_ids: @token.id)
    end

    assert_equal 1, call_count
  end
end
