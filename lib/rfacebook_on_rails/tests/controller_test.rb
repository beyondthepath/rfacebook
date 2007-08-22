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

# Thank you goes out to Chris Taggart, who insisted on having unit tests :)

require "test/unit"
require "rubygems"
require "mocha"

class DummyController < ActionController::Base
  
  before_filter :require_facebook_login
  
  def index
    render :text => "index"
  end
  
  # Re-raise errors caught by the controller.
  def rescue_action(e) 
    raise e 
  end
  
end

class ControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = DummyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_before_filters_are_present
    assert @controller.respond_to?(:require_facebook_login)
    assert @controller.respond_to?(:require_facebook_install)
    assert @controller.respond_to?(:handle_facebook_login)
  end
  
  def test_facebook_helpers_are_present
    assert @controller.respond_to?(:in_facebook_canvas?)
    assert @controller.respond_to?(:in_facebook_frame?)
    assert @controller.respond_to?(:in_mock_ajax?)
    assert @controller.respond_to?(:in_external_app?)
    assert @controller.respond_to?(:added_facebook_application?)
  end
  
end
