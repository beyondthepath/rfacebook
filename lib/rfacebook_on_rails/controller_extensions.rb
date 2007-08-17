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
    
    
    
      # SECTION: Special Variables
    
      def fbparams
      
        dup_params = (self.params || {}).dup
      
        # try to get fbparams from the params hash
        if (!@fbparams || @fbparams.length <= 0)
          @fbparams = rfacebook_session_holder.get_fb_sig_params(dup_params)
        end
      
        # else, try to get fbparams from the cookies hash
        # TODO: we don't write anything into the cookie, so this is kind of pointless right now
        if (@fbparams.length <= 0)
          @fbparams = rfacebook_session_holder.get_fb_sig_params(cookies)
        end
        
        # TODO: fb_sig_params now includes all friend ids by default, so we can avoid an API call to friends.get
        #       we should extend FacebookWebSession for Rails to make this optimization
      
        return @fbparams
      
      end
      
      def fbsession
        
        # if we are in the canvas, iframe, or mock ajax, we should be able to activate the session here
        if (!rfacebook_session_holder.is_valid? and (in_facebook_canvas? or in_facebook_frame? or in_mock_ajax?))
                  
          # then try to activate it somehow (or retrieve from previous state)
          # these might be nil
          facebookUid = fbparams["user"]
          facebookSessionKey = fbparams["session_key"]
          expirationTime = fbparams["expires"]
      
          if (facebookUid and facebookSessionKey and expirationTime)
            # we have the user id and key from the fb_sig_ params, activate the session
            rfacebook_session_holder.activate_with_previous_session(facebookSessionKey, facebookUid, expirationTime)
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Activated session from inside the canvas"
          else
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK WARNING: Tried to activate session from inside the canvas, but failed"
          end
                      
        end
        
        # if all went well, we should definitely have a valid Facebook session object
        return rfacebook_session_holder
      
      end
    
      # SECTION: Helpful Methods
    
      # DEPRECATED
      def facebook_redirect_to(url)
        RAILS_DEFAULT_LOGGER.info "** RFACEBOOK DEPRECATION NOTICE: facebook_redirect_to is deprecated in RFacebook. Instead, you can use redirect_to like any Rails app."
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
        return (params["fb_sig_in_iframe"] != nil or params["fb_sig_in_canvas"] != nil)
      end
      
      def in_mock_ajax?
        return (params["fb_mockajax_url"] != nil)
      end
      
      def in_external_app?
        return (!params[:fb_sig] and !in_facebook_frame?)
      end
      
      # SECTION: before_filters
          
      def handle_facebook_login
                
        if (!in_facebook_canvas? and !rfacebook_session_holder.is_valid?)            
            
          if params["auth_token"]
            
            # activate with the auth token
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: creating a new Facebook session from auth_token"
            rfacebook_session_holder.activate_with_token(params["auth_token"])
              
            # template method call upon success
            if rfacebook_session_holder.is_valid?
              RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Login was successful, calling finish_facebook_login"
              if in_external_app?
                finish_facebook_login
              end
            end
            
          elsif (session[:rfacebook_session] and session[:rfacebook_session].is_valid?)
            
            # grab saved Facebook session from Rails session
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: grabbing Facebook session from Rails session"
            @rfacebook_session_holder = session[:rfacebook_session]
            @rfacebook_session_holder.logger = RAILS_DEFAULT_LOGGER
          
          end
        
          # warning logs
          if !rfacebook_session_holder.is_valid?
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK WARNING: Facebook session could not be activated (from handle_facebook_login)"
          elsif params["auth_token"]
            # TODO: ignoring is proper when we have already used the auth_token (we could try to reauth and swallow the exception)
            #         however, we probably want to re-auth if the new auth_token is valid (new user, old user probably logged out)
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: received a new auth_token, but we already have a valid session (ignored new auth_token)"
          end
            
        end
        
      end
    
      def require_facebook_login
      
        # handle a facebook login if given (external sites and iframe only)
        handle_facebook_login
      
        # now finish it off depending on whether we are in canvas, iframe, or external app
        if !performed?
                
          # try to get the session
          sess = fbsession
      
          # handle invalid sessions by forcing the user to log in      
          if !sess.is_valid?
          
            RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Session is not valid"
          
            if in_external_app?
              
              RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Redirecting to login for external app"
              redirect_to sess.get_login_url
              return false
              
            elsif (!fbparams or fbparams.size == 0)
              
              RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK WARNING: Failed to activate due to a bad API key or API secret"
              render_text facebook_debug_panel
              return false
              
            else
              
              RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Redirecting to login for canvas app"
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
      
      # SECTION: Facebook Debug Panel
      
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
        return ERB.new(RFacebook::Rails::DEBUG_PANEL_ERB_TEMPLATE).result(Proc.new{}) # TODO: should use File.dirname(__FILE__) + 'templates/debug_panel.rhtml' instead
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
      
      # SECTION: Private Methods
      
      def rfacebook_session_holder
        
        if (@rfacebook_session_holder == nil)
          @rfacebook_session_holder = FacebookWebSession.new(facebook_api_key, facebook_api_secret)
          @rfacebook_session_holder.logger = RAILS_DEFAULT_LOGGER
        end
        
        return @rfacebook_session_holder
        
      end
            
      def rfacebook_persist_session_to_rails
        if (!in_facebook_canvas? and rfacebook_session_holder.is_valid?)
          RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: persisting Facebook session information into Rails session"
          session[:rfacebook_session] = @rfacebook_session_holder.dup
          session[:rfacebook_session].logger = nil # pstore can't serialize the Rails logger
        end
      end
      
      
      # SECTION: URL Management 
      
      CLASSES_EXTENDED = []
            
      def self.included(base)
        
        # check for a double include
        doubleInclude = false
        CLASSES_EXTENDED.each do |klass|
          if base.allocate.is_a?(klass) # TODO: is there a more direct way than allocating an instance and checking is_a?
            doubleInclude = true
          end
        end
        
        if doubleInclude
          RAILS_DEFAULT_LOGGER.info "** RFACEBOOK WARNING: detected double-include of RFacebook controller extensions.  Please see instructions for RFacebook on Rails plugin usage (http://rfacebook.rubyforge.org).  You may be including the deprecated RFacebook::RailsControllerExtensions in addition to the plugin."
          
        else
          CLASSES_EXTENDED << base
          
          # we need to use an eval since we will be overriding ActionController::Base methods
          # and we need to be able to call the originals
          base.class_eval '
      
            alias_method(:url_for__ALIASED, :url_for)
      
            def url_for(options={}, *parameters)
              
              # error check
              if !options
                RAILS_DEFAULT_LOGGER.info "** RFACEBOOK WARNING: options cannot be nil in call to url_for"
              end
              
              # use special URL rewriting when inside the canvas
              # setting the mock_ajax option to true will override this
              # and force usage of regular Rails rewriting
              if (in_facebook_canvas? and !options[:mock_ajax]) #TODO: or in_facebook_frame?
                
                if options.is_a? Hash
                  options[:only_path] = true
                end
                
                # try to get a regular URL
                path = url_for__ALIASED(options, *parameters)
                                
                # replace anything that references the callback with the
                # Facebook canvas equivalent (apps.facebook.com/*)
                if (path.starts_with?(self.facebook_callback_path) or "#{path}/".starts_with?(self.facebook_callback_path))
                  path.sub!(self.facebook_callback_path, self.facebook_canvas_path)
                  path = "http://apps.facebook.com#{path}"
                else
                  # default to a full URL (will link externally)
                  RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: failed to get canvas-friendly URL ("+path+") for ["+options.inspect+"], creating an external URL instead"
                  path = "#{request.protocol}#{request.host}:#{request.port}#{path}"
                end
              
              # mock-ajax rewriting
              elsif options[:mock_ajax]
                options.delete(:mock_ajax) # clear it so it doesnt show up in the url
                options[:only_path] = true
                path = "#{request.protocol}#{request.host}:#{request.port}#{url_for__ALIASED(options, *parameters)}"
              
              # regular Rails rewriting
              else
                path = url_for__ALIASED(options, *parameters)
              end
  
              return path
            end
      
          
            alias_method(:redirect_to__ALIASED, :redirect_to)
          
            def redirect_to(options = {}, *parameters)
              if in_facebook_canvas?
                
                canvasRedirUrl = url_for(options, *parameters)
                
                # ensure that we come back to the canvas if we redirect
                # to somewhere else on Facebook
                if canvasRedirUrl.starts_with?("http://www.facebook.com")
                  canvasRedirUrl = "#{canvasRedirUrl}&canvas"
                end
                
                RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Canvas redirect to #{canvasRedirUrl}"
                render :text => "<fb:redirect url=\"#{canvasRedirUrl}\" />"
                
              else
                RAILS_DEFAULT_LOGGER.debug "** RFACEBOOK INFO: Regular redirect_to"
                redirect_to__ALIASED(options, *parameters)
              end
            end
          '
          
          # ensure that we persist the Facebook session in the Rails session (if possible)
          base.after_filter(:rfacebook_persist_session_to_rails)
          
          # fix third party cookies in IE
          base.before_filter{ |c| c.headers['P3P'] = %|CP="NOI DSP COR NID ADMa OPTa OUR NOR"| }
          
        end
      end


    end
  end
end
