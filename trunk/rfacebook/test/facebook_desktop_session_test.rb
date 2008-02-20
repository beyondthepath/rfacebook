require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/facebook_session_test_methods'

class RFacebook::FacebookDesktopSession
  def test_initialize(*params)
    initialize(*params)
  end
end

class FacebookDesktopSessionTest < Test::Unit::TestCase
  
  include FacebookSessionTestMethods
  
  def setup
    # setting up a desktop session means that we need to allow the initialize method to 'access' the API for a createToken request
    @fbsession = RFacebook::FacebookDesktopSession.allocate
    @fbsession.expects(:post_request).returns(RFacebook::Dummy::AUTH_CREATETOKEN_RESPONSE)
    @fbsession.test_initialize(RFacebook::Dummy::API_KEY, RFacebook::Dummy::API_SECRET)
  end
  
  def test_should_return_login_url
    assert_equal "http://www.facebook.com/login.php?v=1.0&api_key=#{RFacebook::Dummy::API_KEY}&auth_token=3e4a22bb2f5ed75114b0fc9995ea85f1&popup=true", @fbsession.get_login_url
  end
  
end
