require File.dirname(__FILE__) + '/facebook_session_test_methods'

class FacebookWebSessionTest < Test::Unit::TestCase
  
  include FacebookSessionTestMethods
  
  def setup
    @fbsession = RFacebook::FacebookWebSession.new(RFacebook::Dummy::API_KEY, RFacebook::Dummy::API_SECRET)
  end
  
  def test_should_return_install_url
    assert_equal "http://www.facebook.com/install.php?api_key=#{RFacebook::Dummy::API_KEY}", @fbsession.get_install_url
  end
  
  def test_should_return_login_url
    assert_equal "http://www.facebook.com/login.php?v=1.0&api_key=#{RFacebook::Dummy::API_KEY}", @fbsession.get_login_url
  end
  
end
