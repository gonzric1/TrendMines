require "test_helper"

class DesignImageTest < ActiveSupport::TestCase
  setup do
    @design = designs(:frieren_sticker)
  end

  test "can attach an image" do
    @design.image.attach(
      io: StringIO.new("fake image data"),
      filename: "test.png",
      content_type: "image/png"
    )

    assert @design.image.attached?
  end

  test "rejects invalid content type" do
    @design.image.attach(
      io: StringIO.new("fake data"),
      filename: "test.txt",
      content_type: "text/plain"
    )

    assert_not @design.valid?
    assert_includes @design.errors[:image], "must be a PNG, JPEG, or WebP file"
  end

  test "accepts png content type" do
    @design.image.attach(
      io: StringIO.new("fake png"),
      filename: "test.png",
      content_type: "image/png"
    )

    assert @design.valid?
  end

  test "accepts jpeg content type" do
    @design.image.attach(
      io: StringIO.new("fake jpeg"),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )

    assert @design.valid?
  end

  test "accepts webp content type" do
    @design.image.attach(
      io: StringIO.new("fake webp"),
      filename: "test.webp",
      content_type: "image/webp"
    )

    assert @design.valid?
  end

  test "rejects files over 10MB" do
    large_data = "x" * (11 * 1024 * 1024)
    @design.image.attach(
      io: StringIO.new(large_data),
      filename: "large.png",
      content_type: "image/png"
    )

    assert_not @design.valid?
    assert_includes @design.errors[:image], "must be less than 10MB"
  end
end
