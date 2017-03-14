# Choose the site being integrated. Values include: 'https://secure.affinipay.com', 'https://secure.lawpay.com', 'https://secure.cpacharge.com'
ENV['SITE']                       = 'https://secure.affinipay.com'
ENV['OAUTH2_CLIENT_ID']           = ''
ENV['OAUTH2_CLIENT_SECRET']       = ''
ENV['OAUTH2_CLIENT_REDIRECT_URI'] = 'http://127.0.0.1:9292/callback'

# Gateway credentials are optional. If not specified, they will be defaulted when the
# Connect flow is performed in the app.
ENV['GATEWAY_PUBLIC_KEY']         = ''
ENV['GATEWAY_SECRET_KEY']         = ''
