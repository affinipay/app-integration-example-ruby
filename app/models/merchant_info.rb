require 'json'

class MerchantInfo
  attr_reader :access_token
  attr_writer :access_token
  attr_reader :test_accounts
  attr_reader :live_accounts
  attr_reader :user
  attr_reader :merchant

  def self.new_w_json(*args)
    # puts 'self.new_w_params(*args)'
    merchant_info = allocate
    merchant_info.init_w_json(*args)
    merchant_info
  end

  def init_w_json(access_token, m)
    # puts 'init_w_json_string(access_token, test_accounts, live_accounts, filename = \'merchant_info.json\')'
    m_info = JSON.parse(m).symbolize_keys
    m_info[:test_accounts].map! { |x| x = x.symbolize_keys } unless m_info[:test_accounts].nil?
    m_info[:live_accounts].map! { |x| x = x.symbolize_keys } unless m_info[:live_accounts].nil?
    @access_token = access_token
    @test_accounts = m_info[:test_accounts]
    @live_accounts = m_info[:live_accounts]
    @user = m_info[:user]
    @merchant = m_info[:merchant]
  end

  def to_json(*a)
    # puts 'to_json(*a)'
    result =  {}
    result[:access_token] = access_token unless access_token.nil?
    result[:test_accounts] = test_accounts unless test_accounts.nil?
    result[:live_accounts] = live_accounts unless live_accounts.nil?
    result[:user] = user unless user.nil?
    result[:merchant] = merchant unless merchant.nil?
    result.to_json(*a)
  end

  def sanitized
    clone = Marshal.load(Marshal.dump(self))
    clone.access_token = nil
    clone.test_accounts.map! { |x| x.delete(:secret_key); x } unless clone.test_accounts.nil?
    clone.live_accounts.map! { |x| x.delete(:secret_key); x } unless clone.live_accounts.nil?
    clone
  end

  def self.json_create(o)
    # puts 'self.json_create(o)'
    new(o['access_token'],o['test_accounts'], o['live_accounts'], o['user'], o['merchant'])
  end

end
