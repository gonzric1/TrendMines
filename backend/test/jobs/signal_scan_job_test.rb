require "test_helper"

class SignalScanJobTest < ActiveSupport::TestCase
  test "job performs without error when no sources are configured" do
    # Stub all source classes to avoid real HTTP calls
    noop = lambda { |*| [] }
    stub_scanner = Object.new
    stub_scanner.define_singleton_method(:configured?) { true }
    stub_scanner.define_singleton_method(:discover) { [] }
    stub_scanner.define_singleton_method(:scan) { |**| [] }

    SignalScanJob::SOURCE_MAP.each_value do |class_name|
      class_name.constantize.stub(:new, stub_scanner) do
        # Just test that it doesn't blow up
      end
    end

    # Simplest approach: stub the one source that's always configured (AO3)
    Sources::FandomStats.stub(:new, stub_scanner) do
      Sources::Reddit.stub(:new, stub_scanner) do
        Sources::Tumblr.stub(:new, stub_scanner) do
          Sources::GoogleTrends.stub(:new, stub_scanner) do
            assert_nothing_raised do
              SignalScanJob.perform_now
            end
          end
        end
      end
    end
  end

  test "run_discovery then run_monitoring works end to end" do
    mock_scanner = Object.new
    mock_scanner.define_singleton_method(:discover) { [] }
    mock_scanner.define_singleton_method(:scan) { |**| [] }

    job = SignalScanJob.new
    assert_nothing_raised do
      job.send(:run_discovery, mock_scanner, "ao3")
      topics = TrendSignal.active.pluck(:topic).uniq
      job.send(:run_monitoring, mock_scanner, "ao3", topics) if topics.any?
    end
  end

  test "source_due? returns true when no last scan recorded" do
    job = SignalScanJob.new
    assert job.send(:source_due?, "reddit")
  end

  test "source_due? returns true when frequency has elapsed" do
    Setting.create!(
      key: "scanning.test_source_last_scan",
      value: 2.hours.ago.iso8601,
      category: "scanning",
      description: "Test"
    )
    Setting.create!(
      key: "scanning.test_source_frequency",
      value: 1,
      category: "scanning",
      description: "Test"
    )

    job = SignalScanJob.new
    assert job.send(:source_due?, "test_source")
  ensure
    Setting.where(key: ["scanning.test_source_last_scan", "scanning.test_source_frequency"]).destroy_all
  end

  test "source_due? returns false when frequency has not elapsed" do
    Setting.create!(
      key: "scanning.test_source2_last_scan",
      value: 10.minutes.ago.iso8601,
      category: "scanning",
      description: "Test"
    )
    Setting.find_or_create_by!(key: "scanning.test_source2_frequency") do |s|
      s.value = 6
      s.category = "scanning"
      s.description = "Test"
    end

    job = SignalScanJob.new
    assert_not job.send(:source_due?, "test_source2")
  ensure
    Setting.where(key: ["scanning.test_source2_last_scan", "scanning.test_source2_frequency"]).destroy_all
  end

  test "record_scan_time creates or updates last_scan setting" do
    job = SignalScanJob.new

    assert_difference "Setting.count", 1 do
      job.send(:record_scan_time, "test_record")
    end

    setting = Setting.find_by(key: "scanning.test_record_last_scan")
    assert_not_nil setting
    assert_equal "scanning", setting.category
    assert Time.parse(setting.value) > 1.minute.ago
  ensure
    Setting.where(key: "scanning.test_record_last_scan").destroy_all
  end

  test "run_discovery calls discover on scanner and upserts results" do
    mock_results = [
      { source: "Test", topic: "Discovered Topic #{SecureRandom.hex(4)}", description: "Auto-discovered", momentum_score: 7.0, raw_data: {} }
    ]

    mock_scanner = Minitest::Mock.new
    mock_scanner.expect(:discover, mock_results)

    job = SignalScanJob.new

    assert_difference "TrendSignal.count", 1 do
      job.send(:run_discovery, mock_scanner, "test")
    end

    mock_scanner.verify
  end
end
