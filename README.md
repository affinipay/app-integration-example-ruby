# End to End Demo

This app demonstrates the key interactions when performing an application-level integration with an
AffiniPay solution through a partner's OAuth application. The app is implemented in
[ruby](https://www.ruby-lang.org) using the [sinatra](http://www.sinatrarb.com/) framework for web
access.

Once started, the application's [index page](http://localhost:9292) provides an
[OAuth2](https://oauth.net/2/) Authorization Code Grant flow via the "Connect" button. This mechanism
allows a business with an existing AffiniPay account to login using their AffiniPay credentials and
securely provide access to their account information to the integration partner. After successful
authentication and approval, the AffiniPay server redirects back to the test app with the OAuth2
authorization code. The app then exchanges the authorization code for an access token using the
configured partner OAuth2 client ID and secret. Finally, the app uses this access token to retrieve
the business's merchant and account data, which provides access keys to the AffiniPay Payment Gateway.

Following the "Connect" flow, the [index page](http://localhost:9292) provides access links to view
the merchant and account information, retrieve recent transactions, and view recent event data from the
Payment Gateway. The [transaction](https://developers.affinipay.com/reference/api.html#Transactions)
and [event](https://developers.affinipay.com/reference/api.html#Events) endpoints demonstrate one
means by which integrating applications can obtain information about changes that occur, such as
charges authorized and captured, for internal reconciliation.

The app also provides a sample [client portal](http://localhost:9292/portal) demonstrating a simple
payment form integration. The page uses the [JavaScript tokenization library](https://developers.affinipay.com/guides/payment-form-getting-started.html)
to exchange confidential payment details for a one-time payment token. The token is retrieved directly
in the browser, via a direct secure connection to the Payment Gateway. Once retrieved, the token is
POSTed to the application's `/pay_invoice` endpoint, which securely authorizes the payment via the
Payment Gateway using the credentials obtained by the "Connect" flow.

## Installation

- Install ruby and the bundler gem

- Install all dependencies with: 'bundle install'

## Configuration

### 1) Contact AffiniPay Support to create a partner OAuth2 application for you

Support will provision a private OAuth2 application with which you can test your integration. When you
are ready to go live, Support will assist with making your application public for your customers to use.

### 2) Configure OAuth and Redirect URI

Login to your AffiniPay account, click the user menu, and select `Developers` to display your partner
application. Click the `Edit` button to configure your application. Make sure to enable OAuth, and
set `http://127.0.0.1:9292/callback` in the `redirect uri` field.

### 3) Retrieve your AffiniPay Partner Application Client ID and Secret

Copy the `OAuth Client ID` and `OAuth Secret` displayed in the application configuration into the
`env.rb` file location in this application's root folder.

    # env.rb
    ENV['OAUTH2_CLIENT_ID']           = "129477f..."
    ENV['OAUTH2_CLIENT_SECRET']       = "c1eec90..."
    ENV['OAUTH2_CLIENT_REDIRECT_URI'] = "http://127.0.0.1:9292/callback"


### 4) Start the server

Fire up the app server with:

    rackup config.ru

You should now be able to start using the app by opening the [index page](http://127.0.0.1:9292) in your
browser.
