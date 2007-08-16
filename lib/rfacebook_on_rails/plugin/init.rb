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

require "digest/md5"
require "cgi"

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
# TODO: also parse for full URLs beginning with HTTP (see: http://rubyforge.org/tracker/index.php?func=detail&aid=13096&group_id=3607&atid=13796)
def ensureLeadingAndTrailingSlashesForPath(path)
  if (path and path.size>0)
    if !path.starts_with?("/")
      path = "/#{path}"
    end
    if !path.reverse.starts_with?("/")
      path = "#{path}/"
    end
    return path
  else
    return nil
  end
end

FACEBOOK["canvas_path"] = ensureLeadingAndTrailingSlashesForPath(FACEBOOK["canvas_path"]).strip
FACEBOOK["callback_path"] = ensureLeadingAndTrailingSlashesForPath(FACEBOOK["callback_path"]).strip

# inject methods
ActionView::Base.send(:include, RFacebook::Rails::ViewExtensions)
ActionView::Base.send(:include, RFacebook::Rails::Plugin::ViewExtensions)

ActionController::Base.send(:include, RFacebook::Rails::ControllerExtensions)
ActionController::Base.send(:include, RFacebook::Rails::Plugin::ControllerExtensions)

ActiveRecord::Base.send(:include, RFacebook::Rails::ModelExtensions)
ActiveRecord::Base.send(:include, RFacebook::Rails::Plugin::ModelExtensions)


class CGI::Session

  alias :initialize__ALIASED :initialize
  alias :new_session__ALIASED :new_session
  
  def using_facebook_session_id?
    return @using_fb_session_id
  end
  
  def force_to_be_new!
    @force_to_be_new = true
  end
  
  def new_session
    if @force_to_be_new
      return true
    else
      return new_session__ALIASED
    end
  end

  def initialize(request, options = {})
    
    # check the environment to find a Facebook sig_session_key (credit: Blake Carlson and David Troy)
    fbsessionId = nil
    ["RAW_POST_DATA", "QUERY_STRING", "HTTP_REFERER"].each do |tableSource|
      if request.env_table[tableSource]
        fbsessionId = CGI::parse(request.env_table[tableSource]).fetch('fb_sig_session_key'){[]}.first
        RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: checked #{tableSource} for Facebook session id and got [#{fbsessionId}]"
      end
      break if fbsessionId
    end

    # we only want to change the session_id if we got one from the fb_sig
    if fbsessionId
      options['session_id'] = Digest::MD5.hexdigest(fbsessionId)
      @using_facebook_session_id = true
      RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: using MD5 of Facebook session id [#{options['session_id']}] for the Rails session id}"
    end
    
    # now call the default Rails session initialization
    initialize__ALIASED(request, options)
  end
end

# NOTE: the following extensions allow ActiveRecord and PStore to use the Facebook session id for sessions
#       Their implementation warrants another look.  Ideally, we'd like to solve this further up the chain
#       so that sessions will work no matter what store you have
#       ...maybe we could just override CGI::Session#session_id? what are the consequences?

# TODO: support other session stores (like MemCached, etc.)

# force ActiveRecordStore to use the Facebook session id (credit: Blake Carlson)
class CGI
  class Session
    class ActiveRecordStore
      alias :initialize__ALIASED :initialize
      def initialize(session, options = nil)
        initialize__ALIASED(session, options)
        session_id = session.session_id
        unless @session = ActiveRecord::Base.silence { @@session_class.find_by_session_id(session_id) }
          # FIXME: technically this might be a security problem, since an external browser can grab any unused session id they want
          @session = @@session_class.new(:session_id => session_id, :data => {})
        end
      end      
    end
  end
end

# force PStore to use the Facebook session id
class CGI
  class Session
    class PStore
      alias :initialize__ALIASED :initialize
      def initialize(session, options = nil)
        begin
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: inside PStore, with session_id: #{session.session_id}, new_session = #{session.new_session ? 'yes' : 'no'}"
          initialize__ALIASED(session, options)
        rescue Exception => e 
          begin
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: failed to init PStore session, trying to make a new session"
            # FIXME: technically this might be a security problem, since an external browser can grab any unused session id they want
            if session.session_id
              session.force_to_be_new!
            end
            initialize__ALIASED(session, options)
          rescue Exception => e
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: failed to create a new PStore session falling back to default Rails behavior"
            raise e
          end
        end
      end      
    end
  end
end
