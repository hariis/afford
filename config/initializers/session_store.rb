# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rr10-team-214_session',
  :secret      => '0fb8efd42de88abe7fbbaf198be3c63595049d7be7d07e77c302d22cecc5811c137fbdbac69408bc1d20d4c0f5a18ba6ed4ecc7b31a41cd4520900ead54d0323'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
