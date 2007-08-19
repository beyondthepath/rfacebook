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

require "digest/md5"
require "cgi"

# patch up the CGI session module to use Facebook session keys when cookies aren't available
class CGI::Session

  alias :initialize__ALIASED :initialize
  alias :new_session__ALIASED :new_session
  
  def using_facebook_session_id?
    return (@fb_sig_session_id != nil)
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
    
    @fb_sig_session_id = nil
    
    # first check the environment to find a Facebook sig_session_key (credit: Blake Carlson and David Troy)
    if !@fb_sig_session_id
      begin
        envTable = request.send(:env_table) || request.send(:env)
        ["RAW_POST_DATA", "QUERY_STRING"].each do |tableSource|
          if envTable[tableSource]
            @fb_sig_session_id = CGI::parse(envTable[tableSource]).fetch('fb_sig_session_key'){[]}.first
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: checked env_table.#{tableSource} for Facebook session id and got [#{@fb_sig_session_id}]"
          end
          break if @fb_sig_session_id
        end
      rescue
        RAILS_DEFAULT_LOGGER.info "** RFACEBOOK WARNING: Couldn't check env_table for some reason"
      end
    end
    
    # if that fails (since it was accessing internals that may have changed), check the request.parameters instead
    # Depending on the user's version of Rails, this may fail due to a bug in Rails parsing of
    # nil keys: http://dev.rubyonrails.org/ticket/5137
    if !@fb_sig_session_id
      begin
        @fb_sig_session_id = request.parameters['fb_sig_session_key']
        RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: checked request.parameters for Facebook session id and got [#{@fb_sig_session_id}]"
      rescue Exception => e
        RAILS_DEFAULT_LOGGER.debug e.backtrace
        RAILS_DEFAULT_LOGGER.info "** RFACEBOOK WARNING: Couldn't check request.parameters for some reason"
      end
    end
  
    # we only want to change the session_id if we got one from the fb_sig
    if @fb_sig_session_id
      options['session_id'] = Digest::MD5.hexdigest(@fb_sig_session_id)
      RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: using MD5 of Facebook session id [#{options['session_id']}] for the Rails session id}"
    end
    
    # now call the default Rails session initialization
    initialize__ALIASED(request, options)
  end
end

# Module: SessionStoreExtensions
#
#   Special initialize method that forces any session store to use the Facebook session
module RFacebook::Rails::SessionStoreExtensions
  def initialize__RFACEBOOK(session, options, *extraParams)
    
    if session.using_facebook_session_id?
      
      # we got the fb_sig_session_key, so alter Rails' behavior to use that key to make a session
      begin
        RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: inside #{self.class.to_s}, with session_id: #{session.session_id}, new_session = #{session.new_session ? 'yes' : 'no'}"
        initialize__ALIASED(session, options, *extraParams)
      rescue Exception => e 
        begin
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: failed to init #{self.class.to_s} session, trying to make a new session"
          # FIXME: technically this might be a security problem, since an external browser can grab any unused session id they want
          if session.session_id
            session.force_to_be_new!
          end
          initialize__ALIASED(session, options, *extraParams)
        rescue Exception => e
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: failed to create a new #{self.class.to_s} session falling back to default Rails behavior"
          raise e
        end
      end
    else
      
      # we didn't get the fb_sig_session_key, so don't alter Rails' behavior
      RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: using default Rails sessions (since we didn't find an fb_sig_session_key in the environment)"
      initialize__ALIASED(session, options, *extraParams)
      
    end
  end
end
