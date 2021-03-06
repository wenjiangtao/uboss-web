require 'openssl'
require 'base64'

module CryptService extend self

  def cipher
    OpenSSL::Cipher::Cipher.new('aes-256-cbc')
  end

  def cipher_key
    Rails.application.secrets.crypt_key
  end

  def decrypt(value)
    c = cipher.decrypt
    c.key = Digest::SHA256.digest(cipher_key)
    c.update(Base64.decode64(value.to_s)) + c.final
  rescue => e
    raise e if Rails.env.development?
    Airbrake.notify_or_ignore(e,
                              parameters: {value: value},
                              cgi_data: ENV.to_hash)
    nil
  end

  def encrypt(value)
    c = cipher.encrypt
    c.key = Digest::SHA256.digest(cipher_key)
    Base64.encode64(c.update(value.to_s) + c.final).chomp
  rescue => e
    raise e if Rails.env.development?
    Airbrake.notify_or_ignore(e,
                              parameters: {value: value},
                              cgi_data: ENV.to_hash)
    nil
  end

  def message_verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.secrets.crypt_key)
  end

  def generate_message(message)
    message_verifier.generate(message)
  end

  def verify_message(message)
    message_verifier.verify(message)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
