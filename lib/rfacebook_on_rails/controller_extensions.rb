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
require "rfacebook_on_rails/status_manager"
require "rfacebook_on_rails/templates/debug_panel"

module RFacebook
  module Rails
    module ControllerExtensions
      
      # SECTION: StandardErrors
    
      class APIKeyNeededStandardError < StandardError; end
      class APISecretNeededStandardError < StandardError; end
      class APICanvasPathNeededStandardError < StandardError; end
      class APICallbackNeededStandardError < StandardError; end
      class APIFinisherNeededStandardError < StandardError; end
    
      # SECTION: Template Methods (must be implemented by concrete subclass)
    
      def facebook_api_key
        raise APIKeyNeededStandardError
      end
    
      def facebook_api_secret
        raise APISecretNeededStandardError
      end
      
      def facebook_canvas_path
        raise APICanvasPathNeededStandardError
      end
      
      def facebook_callback_path
        raise APICallbackNeededStandardError
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
        
        # TODO: fb_sig_params now includes all friend ids by default, so we can avoid an API call to friends.get
        #       we should extend FacebookWebSession for Rails to make this optimization
      
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
            RAILS_DEFAULT_LOGGER.debug "** rfacebook: Activated session from inside the canvas"
          
          elsif (!in_facebook_canvas? and session[:rfacebook_fbsession])
            # Method 2: we've logged in the user already
            @fbsession = session[:rfacebook_fbsession]
          
          end  
        
        end
        
        if @fbsession
          @fbsession.logger = RAILS_DEFAULT_LOGGER
        end
      
        return @fbsession
      
      end
    
      # SECTION: Helpful Methods
    
      # DEPRECATED
      def facebook_redirect_to(url)
        RAILS_DEFAULT_LOGGER.info "DEPRECATION NOTICE: facebook_redirect_to is deprecated in RFacebook. Instead, you can use redirect_to like any Rails app."
        if in_facebook_canvas?
          render :text => "<fb:redirect url=\"#{url}\" />"     
        elsif url =~ /^https?:\/\/([^\/]*\.)?facebook\.com(:\d+)?/i
          render :text => "<script type=\"text/javascript\">\ntop.location.href = \"#{url}\";\n</script>";
        else
          redirect_to url
        end
      end
    
      def in_facebook_canvas?
        return (params["fb_sig_in_canvas"] != nil)
      end
        
      def in_facebook_frame?
        return (params["fb_sig_in_iframe"] != nil || params["fb_sig_in_canvas"] != nil)
      end
      
      def in_external_app?
        return (!params[:fb_sig] and !in_facebook_frame?)
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
          
            if in_external_app?
              RAILS_DEFAULT_LOGGER.debug "** rfacebook: Redirecting to login"
              redirect_to sess.get_login_url
              return false
            elsif (!fbparams or fbparams.size == 0)
              RAILS_DEFAULT_LOGGER.debug "** rfacebook: Failed to activate due to a bad API key or API secret"
              render_text facebook_debug_panel
              return false
            else
              RAILS_DEFAULT_LOGGER.debug "** rfacebook: Rendering canvas redirect"
              render :text => "<fb:redirect url=\"#{sess.get_login_url(:canvas=>true)}\" />"
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
            
      def self.included(base)

        # FIXME: figure out why this is necessary...for some reason, we
        #        can't just define url_for in the module itself (it never gets called)
        base.class_eval '
      
          alias_method(:url_for__ALIASED, :url_for)
      
          def url_for(options={}, *params)
            if !options
              RAILS_DEFAULT_LOGGER.info "** options cannot be nil in call to url_for"
            end
            if in_facebook_canvas? #TODO: or in_facebook_frame?)
              if options.is_a? Hash
                options[:only_path] = true
              end
              path = url_for__ALIASED(options, *params)
              if path.starts_with?(self.facebook_callback_path)
                path.gsub!(self.facebook_callback_path, self.facebook_canvas_path)
                if !options.has_key?(:only_path)
                  path = "http://apps.facebook.com#{path}"
                end
              end
            else
              path = url_for__ALIASED(options, *params)
            end
  
            return path
          end
      
          
          alias_method(:redirect_to__ALIASED, :redirect_to)
          
          def redirect_to(options = {}, *parameters)
            if in_facebook_canvas?
              RAILS_DEFAULT_LOGGER.debug "** Canvas redirect to #{url_for(options)}"
              render :text => "<fb:redirect url=\"#{url_for(options)}\" />"     
            else
              RAILS_DEFAULT_LOGGER.debug "** Regular redirect_to"
              redirect_to__ALIASED(options, *parameters)
            end
          end
        
        '
      end
      
      def render_with_facebook_debug_panel(options={})
        # oldLayout = options[:layout]
        # options[:layout] = false
        begin
          renderedOutput = render_to_string(options)
        rescue # TODO: don't catch-all here, just the exceptions that we originate
          renderedOutput = "Errors prevented this page from rendering properly."
        end
        # options[:text] = "#{facebook_debug_panel}#{renderedOutput}"
        # options[:layout] = oldLayout
        render_text "#{facebook_debug_panel}#{renderedOutput}"
      end
      
      def facebook_debug_panel(options={})
        return ERB.new(RFacebook::Rails::DEBUG_PANEL_ERB_TEMPLATE).result(Proc.new{})
      end
      
      def facebook_status_manager
        checks = [
          SessionStatusCheck.new(self),
          (FacebookParamsStatusCheck.new(self) unless (!in_facebook_canvas? and !in_facebook_frame?)),
          InCanvasStatusCheck.new(self),
          InFrameStatusCheck.new(self),
          (CanvasPathStatusCheck.new(self) unless (!in_facebook_canvas? or !in_facebook_frame?)),
          (CallbackPathStatusCheck.new(self) unless (!in_facebook_canvas? or !in_facebook_frame?)),
          (FinishFacebookLoginStatusCheck.new(self) unless (in_facebook_canvas? or in_facebook_frame?)),
          APIKeyStatusCheck.new(self),
          APISecretStatusCheck.new(self)
          ].compact
        return StatusManager.new(checks)
      end

    end
  end
end
