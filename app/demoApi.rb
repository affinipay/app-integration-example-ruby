require 'sinatra/base'
require 'chargeio'
require_relative 'demo'
# Load partner configuration
raise 'Configuration file env.rb not found!' unless File.exists?('env.rb')
load 'env.rb'

class DemoApi < Demo
  helpers do
    def protected_get!
      return if authorized_get?
      protected_not_authorized!
    end

    def authorized_get?
      request.env['HTTP_X_AFP_APPLICATION_ID'] == ENV['API_APPLICATION_ID'] and request.env['HTTP_X_AFP_CLIENT_KEY'] == ENV['API_CLIENT_KEY']
    end

    def protected!
      return if authorized?
      protected_not_authorized!
    end

    def authorized?
      get_authorized = authorized_get?
      get_authorized and !request.env['HTTP_X_AFP_PUBLIC_KEY'].nil?
    end

    def protected_not_authorized!
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def set_secret_key(account_id)
      found_secret_key = nil
      merchant_info.test_accounts.each { |x|
        found_secret_key = x[:secret_key] unless x[:id] != account_id
      } unless merchant_info.test_accounts.nil?
      merchant_info.live_accounts.each { |x|
        found_secret_key = x[:secret_key] unless x[:id] != account_id
      } unless merchant_info.live_accounts.nil?
      ENV['GATEWAY_SECRET_KEY'] = found_secret_key
      found_secret_key
    end
  end

  def api_access_token
    puts "api access_token. Demo.access_token_string = #{Demo.access_token_string}, Demo.refresh_token_string = #{Demo.refresh_token_string}"
    OAuth2::AccessToken.new(client, Demo.access_token_string, :refresh_token => Demo.refresh_token_string)
  end

  # Get merchant info
  get '/api/v1/merchant' do
    content_type :json # Content-Type: application/json;charset=utf-8
    # puts '/api/v1/merchant_info'

    # Authentication
    protected_get!

    # Return merchant info
    merchant_info.sanitized.to_json
  end

  # Create a charge using one-time token
  post '/api/v1/charge' do
    # puts JSON.pretty_generate(request.env)
    payload = params
    payload = JSON.parse(request.body.read).symbolize_keys unless params[:token_id]
    # puts "payload = #{payload}"
    halt 422, 'Missing Data\n' unless payload.class == Hash

    # Authentication
    protected!

    # Print parameters
    puts "Initiating payment using token #{payload[:token_id]}
          for amount #{payload[:amount]}
          with account_id #{payload[:account_id]}
          with payment_data_source #{payload[:payment_data_source]}
          with pos #{payload[:pos]}
          and payment data source #{payload[:payment_data_source]}"
    halt 422, "Missing token\n" unless !payload[:token_id].nil?
    halt 422, "missing amount\n" unless !payload[:amount].nil?

    # Find the secret key associated with the account id in parameters
    found_secret_key = set_secret_key(payload[:account_id])
    halt 422, "Secret key not found\n" unless !found_secret_key.nil?

    # Create charge parameters
    hash = { }
    hash[:method] = payload[:token_id]
    hash[:ip_address] = params[:ip_address] ? params[:ip_address] : request.ip
    hash[:account_id] = params[:account_id] unless params[:account_id].nil?
    hash[:payment_data_source] = payload[:payment_data_source] unless payload[:payment_data_source].nil?
    hash[:pos] = payload[:pos] unless payload[:pos].nil?
    # puts JSON.pretty_generate(hash)
    # puts JSON.pretty_generate(payload[:amount])

    t = nil
    begin
      t = gateway.charge(payload[:amount], hash)

    rescue Exception => e
      puts 'Caught an exception performing the charge'
      puts "#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map{|s| "\t#{s}"}

      t = ChargeIO::Transaction.new(:gateway => gateway)
      error_code = e.instance_of?(Timeout::Error) ? 'timeout' : 'server_error'
      t.process_response_errors({ 'messages' => [ { 'code' => error_code, 'level' => 'error' } ] })
    end

    if t.errors.present?
      t.attributes['success'] = false
    else
      t.attributes['success'] = true
      session[:last_transaction] = t.attributes.as_json
    end

    json = t.to_json
    # puts "Charge completed: #{json}"
    json
  end

  # Find a transaction
  post '/api/v1/sign' do
    # puts JSON.pretty_generate(request.env)
    payload = params
    payload = JSON.parse(request.body.read).symbolize_keys unless params[:token_id]
    # puts "payload = #{payload}"
    halt 422, 'Missing Data\n' unless payload.class == Hash

    # Authentication
    protected!

    # Check required parameters
    halt 422, "Missing account id\n" unless !payload[:account_id].nil?
    found_secret_key = set_secret_key(payload[:account_id])
    halt 422, "Secret key not found\n" unless !found_secret_key.nil?
    halt 422, "Missing charge id\n" unless !payload[:charge_id].nil?
    halt 422, "Missing signature data id\n" unless !payload[:data].nil?

    # Set gateway secret key
    ENV['GATEWAY_SECRET_KEY'] = found_secret_key

    t = nil
    begin
      t = gateway.sign(payload[:charge_id], payload[:data], nil, 'chargeio/jsignature', {})

    rescue Exception => e
      puts 'Caught an exception performing the charge'
      puts "#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map{|s| "\t#{s}"}

      t = ChargeIO::Transaction.new(:gateway => gateway)
      error_code = e.instance_of?(Timeout::Error) ? 'timeout' : 'server_error'
      t.process_response_errors({ 'messages' => [ { 'code' => error_code, 'level' => 'error' } ] })
    end

    if t.errors.present?
      t.attributes['success'] = false
    else
      t.attributes['success'] = true
      session[:last_transaction] = t.attributes.as_json
    end

    json = t.to_json
    # puts "Charge signed: #{json}"
    json
  end


end
