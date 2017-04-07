require 'sinatra/base'
require './lib/html_renderer'

# Load partner configuration
raise 'Configuration file env.rb not found!' unless File.exists?('env.rb')
load 'env.rb'

class Demo < Sinatra::Base
  # View helpers
  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def pretty_json(json)
      JSON.pretty_generate(json)
    end

    def signed_in?
      !session[:access_token].nil?
    end

    def markdown(text)
      options  = { :autolink => true, :space_after_headers => true, :fenced_code_blocks => true }
      markdown = Redcarpet::Markdown.new(HTMLRenderer, options)
      markdown.render(text)
    end

    def markdown_readme
      markdown(File.read(File.join(File.dirname(__FILE__), 'README.md')))
    end

    def site_name
      case ENV['SITE']
        when 'https://secure.cpacharge.com'
          'CPACharge'
        when 'https://secure.lawpay.com'
          'LawPay'
        else
          'AffiniPay'
      end
    end
  end

  def client(token_method = :post)
    OAuth2::Client.new(
      ENV['OAUTH2_CLIENT_ID'],
      ENV['OAUTH2_CLIENT_SECRET'],
      :site => ENV['SITE'],
      :token_method => token_method,
    )
  end

  def access_token
    OAuth2::AccessToken.new(client, session[:access_token], :refresh_token => session[:refresh_token])
  end

  def redirect_uri
    ENV['OAUTH2_CLIENT_REDIRECT_URI']
  end

  def initialize_merchant
    response = access_token.get('/api/v1/chargeio_credentials')
    merchant_info = JSON.parse(response.body)
    session[:business_name] = merchant_info['merchant']['name']

    # Push the test public and secret keys into the environment for gateway interactions.
    # In a production app, the secret would be stored with the connecting business.
    ENV['GATEWAY_PUBLIC_KEY'] = merchant_info['test_accounts'][0]['public_key']
    ENV['GATEWAY_SECRET_KEY'] = merchant_info['test_accounts'][0]['secret_key']
  end

  # Creates a Payment Gateway client using the gateway credentials
  def gateway
    raise 'No Gateway secret configured' unless ENV['GATEWAY_SECRET_KEY']
    ChargeIO::Gateway.new(:secret_key => ENV['GATEWAY_SECRET_KEY'])
  end

  # Main business view
  get '/' do
    erb :home
  end

  # Initiate OAuth2 Authorization Code Grant flow
  get '/sign_in' do
    redirect client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => 'chargeio')
  end

  # Lightweight logout. Note that if the user's AffiniPay session cookie is stil active from the login,
  # a subsequent execution of the grant flow will not force re-login. To do so, first log out of the
  # AffiniPay app.
  get '/sign_out' do
    session[:access_token] = nil
    redirect '/'
  end

  # OAuth callback invoked by AffiniPay to provide the authorization code, which performs the exchange
  # for the access token using the OAuth application client ID and secret.
  get '/callback' do
    if params[:error]
      erb :home
    else
      begin
        new_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
        session[:access_token]  = new_token.token
        session[:refresh_token] = new_token.refresh_token
        initialize_merchant
        redirect '/'
      rescue OAuth2::Error => @error
        erb :error, :layout => !request.xhr?
      end
    end
  end

  # Obtains merchant and account information, including Payment Gateway credentials, using the access token
  get '/merchant_info' do
    begin
      response = access_token.get('/api/v1/chargeio_credentials')
      @json = JSON.parse(response.body)
      erb :explore, :layout => !request.xhr?
    rescue OAuth2::Error => @error
      erb :error, :layout => !request.xhr?
    end
  end

  # Retrieves recent transactions from the Payment Gateway
  get '/transactions' do
    begin
      results = gateway.transactions
      @json = results.collect { |t| t.attributes.as_json }.to_a
      erb :explore, :layout => !request.xhr?
    rescue OAuth2::Error => @error
      erb :error, :layout => !request.xhr?
    end
  end

  # Retrieves recent events from the Payment Gateway
  get '/events' do
    begin
      results = gateway.events
      @json = results.collect { |t| t.attributes.as_json }.to_a
      erb :explore, :layout => !request.xhr?
    rescue OAuth2::Error => @error
      erb :error, :layout => !request.xhr?
    end
  end

  # Client portal view
  get '/portal' do
    erb :portal, :layout => :layout_portal, :locals => { :amount => Money.new(rand(1000..500000), 'USD') }
  end

  # AJAX handler for running a payment from the client portal. An authorization is performed against the
  # Payment Gateway, and the resulting transaction details are returned to the browser. The details are also
  # stored in the session for access in the receipt view.
  post '/pay_invoice', :provides => :json do
    puts "Initiating payment using token #{params[:token_id]} for amount #{params[:amount]}"

    t = nil
    begin
      t = gateway.charge(params[:amount], { :ip_address => request.ip, :method => params[:token_id] })

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
    puts "Charge completed: #{json}"
    json
  end

  # Displays a simple receipt for the payment
  get '/invoice_receipt' do
    t = session[:last_transaction]
    erb :receipt, :layout => :layout_portal, :locals => {
        :amount => Money.new(t['amount'], t['currency']),
        :auth_code => t['authorization_code']
    }
  end
end
