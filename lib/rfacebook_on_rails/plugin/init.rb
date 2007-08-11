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

module RFacebook
  module Rails
    module Plugin
      #####
      module ControllerExtensions
        def facebook_api_key
          FACEBOOK["key"]
        end
        def facebook_api_secret
          FACEBOOK["secret"]
        end
        def facebook_canvas_path
          FACEBOOK["canvas_path"]
        end
        def facebook_callback_path
          FACEBOOK["callback_path"]
        end
      end  
      #####
      module ModelExtensions
        def facebook_api_key
          FACEBOOK["key"]
        end
        def facebook_api_secret
          FACEBOOK["secret"]
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
def ensureLeadingAndTrailingSlashesForPath(path)
  if !path.starts_with?("/")
    path = "/#{path}"
  end
  if !path.reverse.starts_with?("/")
    path = "#{path}/"
  end
  return path
end

FACEBOOK["canvas_path"] = ensureLeadingAndTrailingSlashesForPath(FACEBOOK["canvas_path"])
FACEBOOK["callback_path"] = ensureLeadingAndTrailingSlashesForPath(FACEBOOK["callback_path"])

# inject methods
ActionView::Base.send(:include, RFacebook::Rails::ViewExtensions)
ActionView::Base.send(:include, RFacebook::Rails::Plugin::ViewExtensions)

ActionController::Base.send(:include, RFacebook::Rails::ControllerExtensions)
ActionController::Base.send(:include, RFacebook::Rails::Plugin::ControllerExtensions)

ActiveRecord::Base.send(:include, RFacebook::Rails::ModelExtensions)
ActiveRecord::Base.send(:include, RFacebook::Rails::Plugin::ModelExtensions)
