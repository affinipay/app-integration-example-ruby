require 'json'

class Account
  attr_reader :score
  attr_reader :id
  attr_reader :name
  attr_reader :type
  attr_reader :currency
  attr_reader :public_key
  attr_reader :secret_key
  attr_reader :trust_account

  def initialize(id, name, type, currency, public_key, secret_key, trust_account)
    @score = 0
    @id = id
    @name = name
    @type = type
    @currency = currency
    @public_key = public_key
    @secret_key = secret_key
    @trust_account = trust_account
  end

  def self.new_by_score(*args)
    account = allocate
    account.init_score(*args)
    account
  end

  def init_score(_score)
    @score = _score
  end


  def to_json(*a)
    {
        'id' => id, 'name' => name, 'type' => type, 'currency' => @currency, 'public_key' => public_key,
        'secret_key' => secret_key, 'trust_account' => trust_account
    }.to_json(*a)
  end

  def self.json_create(o)
    # puts o['id']
    # puts o['name']
    # puts o['type']
    # puts o['currency']
    # puts o['public_key']
    # puts o['secret_key']
    # puts o['trust_account']
    new(o['id'], o['name'], o['type'], o['currency'], o['public_key'],
        o['secret_key'], o['trust_account'])
  end

  def hit(pin_count)
    @score += pin_count
  end
end