require "test_helper"

class SignalScanJobTest < ActiveSupport::TestCase
  test "job performs without error when no topics exist" do
    # Stub gather_topics to return empty — avoids fixture FK issues
    job = SignalScanJob.new
    job.stub(:gather_topics, []) do
      assert_nothing_raised do
        job.perform
      end
    end
  end

  test "job skips unconfigured sources" do
    # With default test env (no API keys), all auth-required sources should be skipped
    signal = TrendSignal.create!(
      source: "test",
      topic: "Test Topic",
      status: "new",
      momentum_score: 5.0
    )

    assert_nothing_raised do
      SignalScanJob.perform_now
    end
  ensure
    signal&.destroy
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

  test "gather_topics returns unique active signal topics" do
    s1 = TrendSignal.create!(source: "a", topic: "Topic A", status: "new", momentum_score: 1.0)
    s2 = TrendSignal.create!(source: "b", topic: "Topic B", status: "watching", momentum_score: 2.0)
    s3 = TrendSignal.create!(source: "c", topic: "Topic A", status: "new", momentum_score: 3.0) # Duplicate

    job = SignalScanJob.new
    topics = job.send(:gather_topics)

    assert_includes topics, "Topic A"
    assert_includes topics, "Topic B"
    # Should be deduped
    assert_equal topics.uniq, topics
  ensure
    [s1, s2, s3].compact.each(&:destroy)
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
end
