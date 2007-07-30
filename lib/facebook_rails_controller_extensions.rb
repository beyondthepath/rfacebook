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

require "facebook_web_session"

module RFacebook
  
  module RailsControllerExtensions
            
    # SECTION: StandardErrors
    
    class APIKeyNeededStandardError < StandardError; end
    class APISecretNeededStandardError < StandardError; end
    class APIFinisherNeededStandardError < StandardError; end
    
    # SECTION: Template Methods (must be implemented by concrete subclass)
    
    def facebook_api_key
      raise APIKeyNeededStandardError
    end
    
    def facebook_api_secret
      raise APISecretNeededStandardError
    end
    
    def finish_facebook_login
      raise APIFinisherNeededStandardError
    end
    
    
    
    # SECTION: Required Methods
    
    def fbparams
      
      dup_params = (self.params || {}).dup
      
      # try to get fbparams from the params hash
      if (!@fbparams || @fbparams.length <= 0)
        @fbparams = fbsession.get_fb_sig_params(dup_params)
      end
      
      # else, try to get fbparams from the cookies hash
      # TODO: we don't write anything into the cookie, so this is kind of pointless right now
      if (@fbparams.length <= 0)
        @fbparams = fbsession.get_fb_sig_params(cookies)
      end
      
      return @fbparams
      
    end

    def fbsession
      
      if !@fbsession
        
        # create a session no matter what
        @fbsession = FacebookWebSession.new(facebook_api_key, facebook_api_secret)
        
        # then try to activate it somehow (or retrieve from previous state)
        # these might be nil
        facebookUid = fbparams["user"]
        facebookSessionKey = fbparams["session_key"]
        expirationTime = fbparams["expires"]
        
        if (facebookUid and facebookSessionKey and expirationTime)
          # Method 1: we have the user id and key from the fb_sig_ params
          @fbsession.activate_with_previous_session(facebookSessionKey, facebookUid, expirationTime)
          
        elsif (!in_facebook_canvas? and session[:rfacebook_fbsession])
          # Method 2: we've logged in the user already
          @fbsession = session[:rfacebook_fbsession]
          
        end  
        
      end
      
      return @fbsession
      
    end
    
    # SECTION: Helpful Methods
    
    def facebook_redirect_to(url)
      if in_facebook_canvas?
        render :text => "<fb:redirect url=\"#{url}\" />"     
      elsif url =~ /^https?:\/\/([^\/]*\.)?facebook\.com(:\d+)?/i
        render :text => "<script type=\"text/javascript\">\ntop.location.href = \"#{url}\";\n</script>";
      else
        redirect_to url
      end
    end
    
    def in_facebook_canvas?
      return (fbparams["in_canvas"] != nil)
    end
        
    def in_facebook_frame?
      return (fbparams["in_iframe"] != nil || fbparams["in_canvas"] != nil)
    end
    
    def handle_facebook_login

      if (params["auth_token"] and !in_facebook_canvas?)
        
        # create a session
        session[:rfacebook_fbsession] = FacebookWebSession.new(facebook_api_key, facebook_api_secret)
        session[:rfacebook_fbsession].activate_with_token(params["auth_token"])
        
        # template method call upon success
        if session[:rfacebook_fbsession].is_valid?
          RAILS_DEFAULT_LOGGER.debug "** rfacebook: Login was successful, calling finish_facebook_login"
          finish_facebook_login
        end
        
      else
        RAILS_DEFAULT_LOGGER.debug "** rfacebook: Didn't activate session from handle_facebook_login"
      end
      
    end
    
    def require_facebook_login
      
      # handle a facebook login if given (external sites and iframe only)
      handle_facebook_login
      
      if !performed?
        
        RAILS_DEFAULT_LOGGER.debug "** rfacebook: Rendering has not been performed"
        
        # try to get the session
        sess = fbsession
      
        # handle invalid sessions by forcing the user to log in      
        if !sess.is_valid?
          
          RAILS_DEFAULT_LOGGER.debug "** rfacebook: Session is not valid"
          
          if in_facebook_canvas?
            RAILS_DEFAULT_LOGGER.debug "** rfacebook: Rendering canvas redirect"
            render :text => "<fb:redirect url=\"#{sess.get_login_url(:canvas=>true)}\" />"
            return false
          else
            RAILS_DEFAULT_LOGGER.debug "** rfacebook: Redirecting to login"
            redirect_to sess.get_login_url
            return false
          end
        end
      end
      
    end
    
    def require_facebook_install
      sess = fbsession
      if (in_facebook_canvas? and (!sess.is_valid? or (fbparams["added"].to_i != 1)))
        render :text => "<fb:redirect url=\"#{sess.get_install_url}\" />"
      end
    end
    
  end
  
end