module RFacebook
  module Rails
    module Plugin
      module ControllerExtensions
        require "rfacebook_on_rails/controller_extensions"
        include RFacebook::Rails::ControllerExtensions
        def facebook_api_key
          return FACEBOOK['key']
        end
        def facebook_api_secret
          return FACEBOOK['secret']
        end
      end        
    end
  end
end

FACEBOOK = YAML.load_file("#{RAILS_ROOT}/config/facebook.yml")[RAILS_ENV]
ActionController::Base.send(:include, RFacebook::Rails::Plugin::ControllerExtensions)
