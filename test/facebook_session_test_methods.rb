module FacebookSessionTestMethods
  
  def force_to_be_activated(fbsession)
    fbsession.stubs(:ready?).returns(true)
  end
  
  def test_method_missing_dispatches_to_facebook_api
    fbsession = @fbsession.dup
    force_to_be_activated(fbsession)
    fbsession.expects(:remote_call).returns("mocked")
    assert_equal "mocked", fbsession.friends_get
  end
    
  def test_remote_error_causes_fbsession_to_raise_errors
    fbsession = @fbsession.dup
    force_to_be_activated(fbsession)
    fbsession.expects(:post_request).returns(RFacebook::Dummy::ERROR_RESPONSE)
    assert_raise(RFacebook::FacebookSession::RemoteStandardError){fbsession.friends_get}
  end
    
  def test_nomethod_error_raises_ruby_equivalent
    fbsession = @fbsession.dup
    force_to_be_activated(fbsession)
    fbsession.expects(:post_request).returns(RFacebook::Dummy::ERROR_RESPONSE_3)
    assert_raise(NoMethodError){fbsession.friends_get}
  end
    
  def test_badargument_error_raises_ruby_equivalent
    fbsession = @fbsession.dup
    force_to_be_activated(fbsession)
    fbsession.expects(:post_request).returns(RFacebook::Dummy::ERROR_RESPONSE_100)
    assert_raise(ArgumentError){fbsession.friends_get}
    fbsession.expects(:post_request).returns(RFacebook::Dummy::ERROR_RESPONSE_606)
    assert_raise(ArgumentError){fbsession.friends_get}
  end
    
  def test_expiration_error_raises_error_and_sets_expired_flag
    fbsession = @fbsession.dup
    force_to_be_activated(fbsession)
    fbsession.expects(:post_request).returns(RFacebook::Dummy::ERROR_RESPONSE_102)
    assert_raise(RFacebook::FacebookSession::ExpiredSessionStandardError){fbsession.friends_get}
    assert fbsession.expired?
  end
  
  def test_facepricot_response_to_group_getMembers
    fbsession = @fbsession.dup
    force_to_be_activated(fbsession)
    fbsession.expects(:post_request).returns(RFacebook::Dummy::GROUP_GETMEMBERS_RESPONSE)
    memberInfo = fbsession.group_getMembers
    assert memberInfo
    assert_equal 4, memberInfo.members.uid_list.size
    assert_equal 1, memberInfo.admins.uid_list.size
    assert memberInfo.officers
    assert memberInfo.not_replied
  end
  
  def test_api_call_to_users_getLoggedInUser
    fbsession = @fbsession.dup
    force_to_be_activated(fbsession)
    fbsession.expects(:post_request).returns(RFacebook::Dummy::USERS_GETLOGGEDINUSER_RESPONSE)
    assert_equal "1234567", fbsession.users_getLoggedInUser
  end

  def test_api_call_to_users_getInfo
    fbsession = @fbsession.dup
    force_to_be_activated(fbsession)
    fbsession.expects(:post_request).returns(RFacebook::Dummy::USERS_GETINFO_RESPONSE)
    userInfo = fbsession.users_getInfo    
    assert userInfo
    assert_equal "94303", userInfo.current_location.get(:zip)
  end
  
  def test_should_raise_not_activated
    assert_raise(RFacebook::FacebookSession::NotActivatedStandardError){@fbsession.friends_get}
  end

end
