require "facebook_web_session"

module RFacebook
  
  module RailsControllerExtensions
    
        
    # SECTION: Exceptions
    
    class APIKeyNeededException < Exception; end
    class APISecretNeededException < Exception; end
    
    # SECTION: Template Methods (must be implemented by concrete subclass)
    
    def facebook_api_key
      raise APIKeyNeededException
    end
    
    def facebook_api_secret
      raise APISecretNeededException
    end
    
    
    
    # SECTION: Required Methods
    
    def fbparams
      
      @fbparams ||= {};
      
      # try to get fbparams from the params hash
      if (@fbparams.length <= 0)
        @fbparams = fbsession.get_fb_sig_params(params)
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
        
        # create a Facebook session that can be used by the controller
        @fbsession = FacebookWebSession.new(facebook_api_key, facebook_api_secret)

        # now we need to activate the session somehow.  If the signature parameters are bad, then we don't make the session
        if fbparams
          # these might be nil
          facebookUid = fbparams["user"]
          facebookSessionKey = fbparams["session_key"]
          expirationTime = fbparams["expires"]
        
          # Method 1: user logged in and was redirected to our site (iframe/external)
          if ( params["auth_token"] )
            @fbsession.activate_with_token(params["auth_token"])
          # Method 2: we have the user id and key from the fb_sig_ params
          elsif (facebookUid and facebookSessionKey and expirationTime)
            @fbsession.activate_with_previous_session(facebookSessionKey, facebookUid, expirationTime)
          end  
        end
        
      end
      
      return @fbsession
      
    end
    
    # SECTION: Helpful Methods
    
    def facebook_redirect_to(url)
      
      if (in_facebook_canvas? and !in_facebook_iframe?)
        render :text => "<fb:redirect url=\"#{url}\" />"
    
      elsif url =~ /^https?:\/\/([^\/]*\.)?facebook\.com(:\d+)?/i # TODO: why doesn't this just check for iframe?
        render :text => "<script type=\"text/javascript\">\ntop.location.href = \"#{url}\";\n</script>"
        
      else
        redirect_to url
        
      end
      
    end
    
    def in_facebook_canvas?
      return (fbparams["in_fbframe"] != nil)
    end
        
    def in_facebook_iframe?
      return (fbparams["in_iframe"] != nil)
    end
    
    def require_facebook_login
      sess = fbsession
      if (sess and !sess.is_valid?)
        if in_facebook_canvas?
          render :text => "<fb:redirect url=\"#{sess.get_login_url(:canvas=>true)}\" />"
        else
          redirect_to sess.get_login_url
        end
      end
    end
    
    def require_facebook_install
      sess = fbsession
      if (sess and !sess.is_valid? and in_facebook_canvas?)
        render :text => "<fb:redirect url=\"#{sess.get_install_url(:canvas=>true)}\" />"
      end
    end
    
  end
  
end