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

require File.dirname(__FILE__) + "/test_helper"
require "test/unit"
require "rubygems"
require "mocha"

class APITest < Test::Unit::TestCase
    
  def test_fbsession_methods_are_present
    assert @controller.fbsession.respond_to?(:session_user_id)
    assert @controller.fbsession.respond_to?(:session_key)
    assert @controller.fbsession.respond_to?(:session_expires)
    assert @controller.fbsession.respond_to?(:last_error_message), "This assertion is OK to fail with RFacebook Gem <= 0.9.1"
    assert @controller.fbsession.respond_to?(:suppress_errors), "This assertion is OK to fail with RFacebook Gem <= 0.9.1"
    assert @controller.fbsession.respond_to?(:suppress_errors=), "This assertion is OK to fail with RFacebook Gem <= 0.9.1"
    assert @controller.fbsession.respond_to?(:logger)
    assert @controller.fbsession.respond_to?(:logger=)
    assert @controller.fbsession.respond_to?(:is_activated?) # alias for "is_ready?"
    assert @controller.fbsession.respond_to?(:is_expired?), "This assertion is OK to fail with RFacebook Gem <= 0.9.1"
    assert @controller.fbsession.respond_to?(:is_ready?), "This assertion is OK to fail with RFacebook Gem <= 0.9.1"    
  end
  
  def test_method_missing_dispatches_to_facebook_api
    @controller.fbsession.expects(:call_method).returns("mocked")
    assert_equal "mocked", @controller.fbsession.some_method_that_doesnt_exist
  end
    
  def test_remote_error_causes_fbsession_to_raise_errors    
    # stub out the response to be a Facebook error
    fbsessionDup = @controller.fbsession.dup
    fbsessionDup.expects(:post_request).returns @dummy_error_response
    assert_raise(RFacebook::FacebookSession::RemoteStandardError){fbsessionDup.friends_get}
  end
  
  def test_api_call_to_group_getMembers
    
    # stub out the response
    fbsessionDup = @controller.fbsession.dup
    fbsessionDup.expects(:post_request).returns @dummy_group_getMembers_response
    
    # fake the remote call
    memberInfo = fbsessionDup.group_getMembers
    
    # check the response data
    assert memberInfo
    assert_equal memberInfo.members.uid_list.size, 4
    assert_equal memberInfo.admins.uid_list.size, 1
    assert memberInfo.officers
    assert memberInfo.not_replied
    
  end
  
  def test_api_call_to_users_getLoggedInUser
    
    # stub out the response
    fbsessionDup = @controller.fbsession.dup
    fbsessionDup.expects(:post_request).returns @dummy_users_getLoggedInUser_response
    
    # fake the remote call
    assert_equal fbsessionDup.users_getLoggedInUser.response, "1234567"

  end
  
  def test_should_return_install_url
    assert_equal "http://www.facebook.com/install.php?api_key=#{@controller.facebook_api_key}", @controller.fbsession.get_install_url
  end
  
  def test_should_return_login_url
    assert_equal "http://www.facebook.com/login.php?v=1.0&api_key=#{@controller.facebook_api_key}", @controller.fbsession.get_login_url
  end
  
  def test_should_get_valid_fb_sig_params_only_when_valid
    
    # make a correct set of fb_sig params
    rawParams = {"fb_sig_foo" => "1234", "fb_sig_bar" => "abcd", "fb_sig_time" => Time.now.to_i+48*3600}
    rawParams["fb_sig"] = Digest::MD5.hexdigest("bar=abcdfoo=1234time=#{rawParams["fb_sig_time"]}#{@controller.facebook_api_secret}")
    
    # ensure that fbparams is parsed out from this properly
    fbparams = @controller.fbsession.get_fb_sig_params(rawParams)
    assert fbparams, "fbparams should exist"
    assert_equal 3, fbparams.size, "fbparams should be 3 elements in size (#{fbparams.inspect})"
    assert_equal rawParams["fb_sig_foo"], fbparams["foo"]
    assert_equal rawParams["fb_sig_bar"], fbparams["bar"]
    assert_equal rawParams["fb_sig_time"], fbparams["time"]
    
    # ensure that fbparams is empty when the signature is wrong
    rawParams["fb_sig"] = "badsignature"
    fbparams = @controller.fbsession.get_fb_sig_params(rawParams)
    assert fbparams, "fbparams should exist"
    assert_equal 0, fbparams.size, "fbparams should not be populated (#{fbparams.inspect})"
    
  end





  def setup
    
    # we want to test with the same fbsession that a real controller will get
    @controller = DummyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    # simulate fbsession setup inside canvas
    # (most common usage, but it really doesn't matter for this test case anyway)
    @controller.simulate_inside_canvas
    post :index
    
    assert @controller.fbparams.size > 0, "API Test should have simulated fbparams properly"
    assert @controller.fbsession.is_ready?, "API Test should have an fbsession that is ready to go"
    
    # set up some dummy responses from the API
    @dummy_error_response = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <error_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
        <error_code>5</error_code>
        <error_msg>Unauthorized source IP address (ip was: 10.1.2.3)</error_msg>
        <request_args list="true">
          <arg>
            <key>method</key>
            <value>facebook.friends.get</value>
          </arg>
          <arg>
            <key>session_key</key>
            <value>373443c857fcda2e410e349c-i7nF4PqX4IW4.</value>
          </arg>
          <arg>
            <key>api_key</key>
            <value>0289b21f46b2ee642d5c42145df5489f</value>
          </arg>
          <arg>
            <key>call_id</key>
            <value>1170813376.3544</value>
          </arg>
          <arg>
            <key>v</key>
            <value>1.0</value>
          </arg>
          <arg>
            <key>sig</key>
            <value>570dcc2b764578af350ea1e1622349a0</value>
          </arg>
        </request_args>
      </error_response>
    EOF
    
    @dummy_auth_getSession_response = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <auth_getSession_response
        xmlns="http://api.facebook.com/1.0/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
          <session_key>5f34e11bfb97c762e439e6a5-8055</session_key>
          <uid>8055</uid>
          <expires>1173309298</expires>
      </auth_getSession_response>
    EOF
    
    @dummy_group_getMembers_response = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <groups_getMembers_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
        <members list="true">
          <uid>4567</uid>
          <uid>5678</uid>
          <uid>6789</uid>
          <uid>7890</uid>
        </members>
        <admins list="true">
          <uid>1234567</uid>
        </admins>
        <officers list="true"/>
        <not_replied list="true"/>
      </groups_getMembers_response>
    EOF
    
    @dummy_users_getLoggedInUser_response = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <users_getLoggedInUser_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1234567</users_getLoggedInUser_response>
    EOF
    
  end

      
end
