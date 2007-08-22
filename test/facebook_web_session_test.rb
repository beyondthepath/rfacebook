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

require "test/unit"
require "rubygems"
require "mocha"

require "facebook_web_session"


# class FacebookWebSessionTest < Test::Unit::TestCase
#   
#   def test_should_raise_not_activated
#     assert_raise(RFacebook::NotActivatedStandardError) { unactivated_session.notifications_sendRequest }
#   end
#   
#   def test_api_calls
#     stub_api_calls
#     assert_equal self.session.notifications_sendRequest, "hello"
#   end
#   
#     
#   # :section: helpers for the unit test
#   
#   def unactivated_session
#     if !@session
#       @session = RFacebook::FacebookWebSession.new("FAKE_API_KEY", "FAKE_API_SECRET")
#     end
#     return @session
#   end
#   
#   def stub_api_calls
#     RFacebook::FacebookWebSession.any_instance.stubs(:post_request).with("facebook.notifications.sendRequest", {}, false).returns("hello")
#     RFacebook::FacebookWebSession.any_instance.stubs(:call_method).returns <<-EOF
# <?xml version="1.0" encoding="UTF-8"?>
# <notifications_sendRequest_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">http://www.facebook.com/send_req.php?from=211031&amp;id=6</notifications_sendRequest_response>
# EOF
#   end
#   
# end
