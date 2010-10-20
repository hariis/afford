# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
if ENV['RAILS_ENV'] == 'production'
  RAILS_GEM_VERSION = '2.3.10' unless defined? RAILS_GEM_VERSION
#else
#  RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION
end
#if ENV['RAILS_ENV'] != 'production'
#  RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION
#end
# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "authlogic"
  config.gem 'twitter'
  config.gem "oauth2", :version => "0.0.8"
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  #config.action_controller.session_store = :active_record_store
  #config.action_controller.session = {:domain => '.caniaffordit.r10.railsrumble.com'}
  
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'
  
  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
  DOMAIN = "http://caniafforditnow.com/" if ENV['RAILS_ENV'] == 'production'
  DOMAIN = "http://localhost:3000/" if ENV['RAILS_ENV'] != 'production'
  TWOAUTH_KEY = ""
  TWOAUTH_SECRET = ""
  TWOAUTH_SITE = "http://twitter.com"
  TWOAUTH_CALLBACK = "http://caniafforditnow.com/callback"
  #redefining the error fields display
  config.action_view.field_error_proc = Proc.new {|html_tag, instance|
    %(<span class="fieldWithErrors">#{html_tag}</span>)}

end
