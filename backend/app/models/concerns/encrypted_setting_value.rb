# Provides symmetric encryption for storing sensitive setting values (API keys)
# in the database. Uses ActiveSupport::MessageEncryptor keyed from secret_key_base.
#
# @example
#   ciphertext = EncryptedSettingValue.encrypt("sk-abc123")
#   plaintext  = EncryptedSettingValue.decrypt(ciphertext)
module EncryptedSettingValue
  class << self
    # Encrypts a plaintext value for storage.
    #
    # @param plaintext [String, nil] The value to encrypt
    # @return [String, nil] Base64-encoded ciphertext, or nil if input is blank
    def encrypt(plaintext)
      return nil if plaintext.blank?
      encryptor.encrypt_and_sign(plaintext)
    end

    # Decrypts a stored ciphertext value.
    #
    # @param ciphertext [String, nil] The encrypted value
    # @return [String, nil] Decrypted plaintext, or nil if input is blank or invalid
    def decrypt(ciphertext)
      return nil if ciphertext.blank?
      encryptor.decrypt_and_verify(ciphertext)
    rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    private

    def encryptor
      key = ActiveSupport::KeyGenerator.new(
        Rails.application.secret_key_base
      ).generate_key("encrypted_setting_value", 32)

      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
