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

class ViewTest < Test::Unit::TestCase
  
  def test_extensions_are_present
    assert @view.respond_to?(:in_facebook_canvas?)
    assert @view.respond_to?(:in_facebook_frame?)
    assert @view.respond_to?(:in_mock_ajax?)
    assert @view.respond_to?(:fbparams)
    assert @view.respond_to?(:fbsession)
    assert @view.respond_to?(:image_path)
    assert @view.respond_to?(:facebook_debug_panel)
  end

  def test_image_path_should_not_rewrite_absolute_urls
    # TODO: implement test
  end
  
  def setup
    @controller = DummyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @view = ActionView::Base.allocate # TODO: how do we unit test views in Rails?
  end
    
end

