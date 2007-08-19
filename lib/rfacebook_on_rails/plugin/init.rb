# Copyright (c) 2007, Matt Pizzimenti (www.livelearncode.com)
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 
# Neither the name of the original author nor the names of contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require "rfacebook_on_rails/view_extensions"
require "rfacebook_on_rails/controller_extensions"
require "rfacebook_on_rails/model_extensions"
require "rfacebook_on_rails/session_extensions"

module RFacebook
  module Rails
    module Plugin
      #####
      module ControllerExtensions
        def facebook_api_key
          FACEBOOK["key"] || super
        end
        def facebook_api_secret
          FACEBOOK["secret"] || super
        end
        def facebook_canvas_path
          FACEBOOK["canvas_path"] || super
        end
        def facebook_callback_path
          FACEBOOK["callback_path"] || super
        end
      end  
      #####
      module ModelExtensions
        def facebook_api_key
          FACEBOOK["key"] || super
        end
        def facebook_api_secret
          FACEBOOK["secret"] || super
        end
      end
      #####
      module ViewExtensions
      end
    end
  end
end

# load Facebook configuration file
begin
  FACEBOOK = YAML.load_file("#{RAILS_ROOT}/config/facebook.yml")[RAILS_ENV]
rescue
  FACEBOOK = {}
end

# make sure the paths have leading and trailing slashes
# TODO: also parse for full URLs beginning with HTTP (see: http://rubyforge.org/tracker/index.php?func=detail&aid=13096&group_id=3607&atid=13796)
def ensureLeadingAndTrailingSlashesForPath(path)
  if (path and path.size>0)
    if !path.starts_with?("/")
      path = "/#{path}"
    end
    if !path.reverse.starts_with?("/")
      path = "#{path}/"
    end
    return path.strip
  else
    return nil
  end
end

FACEBOOK["canvas_path"] = ensureLeadingAndTrailingSlashesForPath(FACEBOOK["canvas_path"])
FACEBOOK["callback_path"] = ensureLeadingAndTrailingSlashesForPath(FACEBOOK["callback_path"])

# inject methods to Rails MVC classes
ActionView::Base.send(:include, RFacebook::Rails::ViewExtensions)
ActionView::Base.send(:include, RFacebook::Rails::Plugin::ViewExtensions)

ActionController::Base.send(:include, RFacebook::Rails::ControllerExtensions)
ActionController::Base.send(:include, RFacebook::Rails::Plugin::ControllerExtensions)

ActiveRecord::Base.send(:include, RFacebook::Rails::ModelExtensions)
ActiveRecord::Base.send(:include, RFacebook::Rails::Plugin::ModelExtensions)

# inject methods to patch Rails session containers
# TODO: document this as API so that everyone knows how to patch their own custom session container
module RFacebook::Rails::Toolbox
  def self.patch_session_store_class(sessionStoreKlass)
    sessionStoreKlass.send(:include, RFacebook::Rails::SessionStoreExtensions)
    sessionStoreKlass.class_eval'
      alias :initialize__ALIASED :initialize
      alias :initialize :initialize__RFACEBOOK
    '
  end
end

# patch as many session stores as possible
RFacebook::Rails::Toolbox::patch_session_store_class(CGI::Session::PStore)
RFacebook::Rails::Toolbox::patch_session_store_class(CGI::Session::ActiveRecordStore)
RFacebook::Rails::Toolbox::patch_session_store_class(CGI::Session::DRbStore)
RFacebook::Rails::Toolbox::patch_session_store_class(CGI::Session::FileStore)
RFacebook::Rails::Toolbox::patch_session_store_class(CGI::Session::MemoryStore)
begin
  RFacebook::Rails::Toolbox::patch_session_store_class(CGI::Session::MemCacheStore)
rescue
  # TODO: this needs to be handled better
end
