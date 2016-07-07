#!/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require

SafeYAML::OPTIONS[:default_mode] = :safe

CONFIG_PATH = File.expand_path('host.yml', File.dirname(__FILE__))
CONFIG = File.open(CONFIG_PATH) {|f| YAML.load(f).freeze }

MENTION = File.expand_path('infra_members.txt', File.dirname(__FILE__))

if ARGV.size < 1
  STDERR.print "Usage: #{$0} environment role\n"
  exit 1
end

environment = ARGV[0]
role = ARGV[1]
REPO = 'vcjp/security-check'
DEPLOY = "#{role}/deployment/#{environment}"
BRANCH = "#{role}/check-update/#{environment}"
update= []

cmd = 'yum --security check-update'

@output = ''
@update_packages = nil
@check_update = nil
@do_yum_update = nil

#def requiredPackageInstalled(host)
#  Net::SSH.start(host, "vagrant", :config => ['./ssh_config']) do |ssh|
#    ssh.open_channel do |channel|
#      channe
#       yum install -y yum-plugin-changelog

def updateExists(host)
  #Net::SSH.start(host, "nagios", :keys => ['~/.ssh/id_dsa_nagios']) do |ssh|
  Net::SSH.start(host, "vagrant", :config => ['./ssh_config']) do |ssh|
    ssh.open_channel do |channel|

      channel.on_data do |ch, data|
        @output << data
      end

      channel.exec("yum -q check-update") do |ch, success|

      end

      channel.on_request "exit-status" do |ch, data|
        #return lambda { return data.read_long}
        @do_yum_update = 'true' if data.read_long == 100
      end

      channel.on_close do |ch|

      end

    end
    ssh.loop
  end
end

def cvesExists(server)
@update_packages = Hash.new
  #Net::SSH.start(server, "nagios", :keys => ['~/.ssh/id_dsa_nagios']) do |ssh|
  Net::SSH.start(server, "vagrant", :config => ['./ssh_config']) do |ssh|
    @check_update.keys.each do |key|
      ssh.open_channel do |channel|

      channel.request_pty

        channel.exec("echo no |sudo yum --changelog update #{key}") do |ch, success|
          abort "fail" unless success
        end
        channel.on_data do |ch,data|
          unless data.scan(/CVE-[0-9]{4}-[0-9]{4}/).empty?
            @update_packages.store(key, data.scan(/CVE-[0-9]{4}-[0-9]{4}/).uniq)
          end
        end
      end
      ssh.loop
    end
  end

  if @check_update.count != '0' then
    puts "#{@update_packages.count} package(s) needed for security, out of #{@check_update.count} available\n"
  end

  @update_packages.each do |key, val|
    puts "#{key.ljust(28)} #{@check_update[key].ljust(20)} #{val}"
  end

end

CONFIG[environment].each do |roles, servers|
  if roles.match("#{role}")
    servers.each do |host|

      catch(:exit) do
      throw :exit if @do_yum_update == 'true'

       updateExists(host)

        #if update_available.call == 100 then
        if @do_yum_update ==  'true' then
          @check_update = Hash.new
          @output.split("\n").each do |line|
            unless line.empty?
              #$check_update.store(line.split(" ")[0].sub(".x86_64", ""), line.split(" ")[1])
              @check_update.store(line.split(" ")[0], line.split(" ")[1])
            end
          end
        cvesExists(host)
          end
       end
    end
  end
end

