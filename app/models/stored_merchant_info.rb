require 'json'
require_relative 'merchant_info'
class StoredMerchantInfo < MerchantInfo
  @@my_mutex = Mutex.new

  def initialize
    @filename = 'merchant_info.json'
  end

  def init_w_json(access_token, m, filename = 'merchant_info.json')
    m_info = JSON.parse(m).symbolize_keys
    m_info[:test_accounts].map! { |x| x = x.symbolize_keys } unless m_info[:test_accounts].nil?
    m_info[:live_accounts].map! { |x| x = x.symbolize_keys } unless m_info[:live_accounts].nil?
    @access_token = access_token
    @test_accounts = m_info[:test_accounts]
    @live_accounts = m_info[:live_accounts]
    @user = m_info[:user]
    @merchant = m_info[:merchant]
    @filename = filename

  end

  def self.new_w_filename(*args)
    merchant_info = allocate
    merchant_info.init_w_filename(*args)
    merchant_info
  end

  def init_w_filename(filename)
    @filename = filename
  end

  def load_from_file
    if @filename
      @@my_mutex.synchronize do
        File.open(@filename, 'r') do |f|
          f.each_line do |line|
            file_content = line
            parsed = JSON.parse(file_content).symbolize_keys
            parsed[:test_accounts].map! { |x| x = x.symbolize_keys } unless parsed[:test_accounts].nil?
            parsed[:live_accounts].map! { |x| x = x.symbolize_keys } unless parsed[:live_accounts].nil?
            @access_token = parsed[:access_token]
            @test_accounts = parsed[:test_accounts]
            @live_accounts = parsed[:live_accounts]
            @user = parsed[:user]
            @merchant = parsed[:merchant]
          end
        end
      end
    end
    self
  end

  def save_to_file
    if @filename
      @@my_mutex.synchronize do
        File.open(@filename, 'w') do |f|
          f.puts self.to_json
        end
      end
    end
  end

  def delete_file
    if @filename
      @@my_mutex.synchronize do
        File.delete(@filename)
      end
    end
  end

  def access_token_string
    load_from_file
    @access_token
  end

end
