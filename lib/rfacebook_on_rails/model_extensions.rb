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


module RFacebook
  module Rails
    module ModelExtensions
      
      # SECTION: StandardErrors
    
      class APIKeyNeededStandardError < StandardError; end
      class APISecretNeededStandardError < StandardError; end
      
      # SECTION: Template Methods (must be implemented by concrete subclass)
    
      def facebook_api_key
        raise APIKeyNeededStandardError
      end
    
      def facebook_api_secret
        raise APISecretNeededStandardError
      end
      
      # SECTION: ActsAs method mixing
      
      def self.included(base)
        base.extend ActsAsMethods
      end

      module ActsAsMethods
        def acts_as_facebook_user
          include RFacebook::Rails::ModelExtensions::ActsAsFacebookUser::InstanceMethods
          extend RFacebook::Rails::ModelExtensions::ActsAsFacebookUser::ClassMethods
        end
      end
      
      
      ##################################################################
      ##################################################################
      # SECTION: Acts As Facebook User
      module ActsAsFacebookUser
        
        ######################
        module ClassMethods
        
          def import_from_facebook_session(sess)
            existingUser = find_by_facebook_session_key(sess.session_key)
            if existingUser
              RAILS_DEFAULT_LOGGER.debug "Tried to create a user that already exists"
              return existingUser
            else
              instance = self.new
              instance.facebook_session = sess
              instance.facebook_session_key = instance.facebook_session.session_key
              instance.facebook_user_id = instance.facebook_session.session_user_id
              return instance
            end
          end
      
          def find(*params)
            instance = super(*params)
            instance.populate_facebook_session!
            return instance
          end
      
          def create(*params)
            instance = super(*params)
            instance.populate_facebook_session!
            self.facebook_session_key = self.facebook_session.session_key
            self.facebook_user_id = self.facebook_session.session_user_id
            if instance.save
              return instance
            else
              return nil
            end
          end
        
        end
      
        ######################
        module InstanceMethods
          attr_accessor :facebook_session
      
          def has_infinite_session_key?
            return self.facebook_session_key != nil
          end
      
          private
      
          def populate_facebook_session!
            begin
              self.facebook_session = FacebookWebSession.new(self.facebook_api_key, self.facebook_api_secret)
              self.facebook_session.activate_with_previous_session(self.facebook_session_key, self.facebook_uid)
            rescue
              self.facebook_session = nil # we don't have a valid session
            end
          end
        end
        
      end
      ##################################################################
      ##################################################################

      
    end    
  end
end