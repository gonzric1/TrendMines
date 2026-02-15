require "test_helper"

class EncryptedSettingValueTest < ActiveSupport::TestCase
  test "encrypts and decrypts a plaintext value" do
    plaintext = "sk-abc123secret"
    ciphertext = EncryptedSettingValue.encrypt(plaintext)

    assert_not_nil ciphertext
    assert_not_equal plaintext, ciphertext

    decrypted = EncryptedSettingValue.decrypt(ciphertext)
    assert_equal plaintext, decrypted
  end

  test "encrypt returns nil for nil input" do
    assert_nil EncryptedSettingValue.encrypt(nil)
  end

  test "encrypt returns nil for blank input" do
    assert_nil EncryptedSettingValue.encrypt("")
  end

  test "decrypt returns nil for nil input" do
    assert_nil EncryptedSettingValue.decrypt(nil)
  end

  test "decrypt returns nil for blank input" do
    assert_nil EncryptedSettingValue.decrypt("")
  end

  test "decrypt returns nil for invalid ciphertext" do
    assert_nil EncryptedSettingValue.decrypt("not-a-valid-encrypted-string")
  end

  test "decrypt returns nil for tampered ciphertext" do
    ciphertext = EncryptedSettingValue.encrypt("secret-key")
    tampered = ciphertext.reverse
    assert_nil EncryptedSettingValue.decrypt(tampered)
  end

  test "different plaintexts produce different ciphertexts" do
    cipher1 = EncryptedSettingValue.encrypt("key-one")
    cipher2 = EncryptedSettingValue.encrypt("key-two")
    assert_not_equal cipher1, cipher2
  end
end
