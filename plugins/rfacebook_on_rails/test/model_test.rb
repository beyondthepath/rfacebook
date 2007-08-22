require "rubygems"

begin
  require File.dirname(__FILE__) + "/test_helper"
  require "rfacebook_on_rails/tests/model_test"
rescue Exception => e
  puts "There was a problem loading the RFacebook on Rails plugin.  You may have forgotten to install the RFacebook Gem."
  raise e
end
