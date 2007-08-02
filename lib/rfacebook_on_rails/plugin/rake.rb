# Rake tasks modified from Evan Weaver's article
# http://blog.evanweaver.com/articles/2007/07/13/developing-a-facebook-app-locally

namespace "facebook" do

  ######################################################################################
  ######################################################################################
  desc "Copy a sample version of facebook.yml to your config directory."
  task "setup_yaml" => "environment" do
    
    filename = "#{RAILS_ROOT}/config/facebook.yml.example"
    puts "Creating #{filename}."

    file = File.new(filename, "w")
    file <<
'
development:
    key: YOUR_API_KEY_HERE
    secret: YOUR_API_SECRET_HERE
    tunnel:
		username: yourLoginName
        host: www.yourexternaldomain.com
        port: 1234
        local_port: 5678

production:
    key: YOUR_API_KEY_HERE
    secret: YOUR_API_SECRET_HERE
    tunnel:
		username: yourLoginName
        host: www.yourexternaldomain.com
        port: 1234
        local_port: 5678
'
    file.close_write
  end
  
  
  namespace "tunnel" do

    ######################################################################################
    ######################################################################################
    desc "Start a reverse tunnel from FACEBOOK['tunnel']['host'] to localhost"
    task "start" => "environment" do
      puts "Tunneling #{FACEBOOK['tunnel']['host']}:#{FACEBOOK['tunnel']['remote_port']} to 0.0.0.0:#{FACEBOOK['tunnel']['local_port']}"
      exec "ssh -nNT -g -R *:#{FACEBOOK['tunnel']['remote_port']}:0.0.0.0:#{FACEBOOK['tunnel']['local_port']} #{FACEBOOK['tunnel']['host']}"
    end
    
    ######################################################################################
    ######################################################################################
    desc "Check if reverse tunnel is running"
    task "status" => "environment" do
      if `ssh #{FACEBOOK['tunnel']['host']} netstat -an | 
          egrep "tcp.*:#{FACEBOOK['tunnel']['remote_port']}.*LISTEN" | wc`.to_i > 0
        puts "Tunnel still running"
      else
        puts "Tunnel is down"
      end
    end
  end


end
