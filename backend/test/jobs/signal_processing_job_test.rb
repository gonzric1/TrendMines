require "test_helper"

class SignalProcessingJobTest < ActiveSupport::TestCase
  test "runs all four phases without error" do
    # Stub all service calls to avoid real HTTP
    Signals::EnrichWithAo3.stub(:call, false) do
      Signals::CorrelateSources.stub(:call, nil) do
        Signals::AutoPromote.stub(:call, nil) do
          assert_nothing_raised do
            SignalProcessingJob.perform_now
          end
        end
      end
    end
  end

  test "handles empty signal set gracefully" do
    # Delete all active signals
    TrendSignal.active.update_all(status: "archived")

    Signals::EnrichWithAo3.stub(:call, false) do
      Signals::CorrelateSources.stub(:call, nil) do
        Signals::AutoPromote.stub(:call, nil) do
          assert_nothing_raised do
            SignalProcessingJob.perform_now
          end
        end
      end
    end
  ensure
    # Restore fixtures
    TrendSignal.where(status: "archived").each do |s|
      s.update_column(:status, s.source == "twitter" ? "watching" : "new") if s.topic.include?("Frieren") || s.topic.include?("Baldur")
    end
  end

  test "error in one signal does not stop processing others" do
    enrich_calls = 0
    enrich_mock = lambda { |signal|
      enrich_calls += 1
      raise "boom" if enrich_calls == 1
      false
    }

    Signals::EnrichWithAo3.stub(:call, enrich_mock) do
      Signals::CorrelateSources.stub(:call, nil) do
        Signals::AutoPromote.stub(:call, nil) do
          assert_nothing_raised do
            SignalProcessingJob.perform_now
          end
          # Should have been called for all active signals despite first error
          assert enrich_calls >= 2 if TrendSignal.active.count >= 2
        end
      end
    end
  end
end
