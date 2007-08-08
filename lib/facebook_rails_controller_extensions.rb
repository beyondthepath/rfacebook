# This file is deprecated, but remains here for backward compatibility
require "rfacebook_on_rails/controller_extensions"
module RFacebook
  module RailsControllerExtensions
    def self.included(base)
      base.send(:include, RFacebook::Rails::ControllerExtensions)
    end
  end
end