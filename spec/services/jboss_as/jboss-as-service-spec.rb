
# Copyright 2009, Red Hat Middleware LLC, and individual contributors
# by the @authors tag. See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'sc-agent/services/jboss_as/jboss-as-service'
require 'openhash/openhash'

module SteamCannon
  describe JBossASService do

    before(:each) do
      @db   = mock(DBHelper)
      @log  = Logger.new('/dev/null')

      ServiceManager.should_receive(:register).and_return( @db )

      @config         = mock('Config', :platform => :ec2)
      @service        = JBossASService.new( :log => @log, :config => @config  )
      @exec_helper    = @service.instance_variable_get(:@exec_helper)
      @service_helper = @service.instance_variable_get(:@service_helper)

      CheckStatusCommand.stub_chain(:new, :execute)
    end

    it "should return status" do
      @service.status.should == { :state => :stopped }
    end

    describe 'artifact' do
      it "should not return the selected artifact" do
        File.should_receive(:exists?).with( @service.deploy_path("not_there.war") ).and_return( false )

        begin
          @service.artifact( "not_there.war" )
          raise "Should raise"
        rescue => e
          e.message.should == "Could not retrieve artifact named 'not_there.war'"
        end
      end

      it "should return the selected artifact" do
        File.should_receive(:exists?).with( @service.deploy_path("there.war") ).and_return( true )
        File.should_receive(:size).with( @service.deploy_path("there.war") ).and_return( 1234 )

        @service.artifact( "there.war" ).should == { :name => 'there.war', :size => 1234 }
      end
    end

    it "should execute configure" do
      cmd = mock(JBossAS::ConfigureCommand)
      cmd.should_receive(:execute).with( :a => :b ).and_return( { :state => :stopped } )

      JBossAS::ConfigureCommand.should_receive(:new).with( @service, :log => @log, :threaded => true ).and_return( cmd )

      @service.configure( :a => :b ).should == { :state => :stopped }
    end

    it "should execute start" do
      @service_helper.should_receive(:execute).with( :start, :backgroud => true ).and_return( { :state => :starting } )
      @service.start.should == { :state => :starting }
    end

    it "should execute stop" do
      @service_helper.should_receive(:execute).with( :stop, :backgroud => true ).and_return( { :state => :stopping } )
      @service.stop.should == { :state => :stopping }
    end

    it "should execute restart" do
      @service_helper.should_receive(:execute).with( :restart, :backgroud => true ).and_return( { :state => :restarting } )
      @service.restart.should == { :state => :restarting }
    end

    it "should return empty list of artifacts" do
      @db.should_receive(:artifacts).and_return([])
      @service.artifacts.should == { :artifacts => [] }
    end

    it "should return list of artifacts" do
      @db.should_receive(:artifacts).and_return([ Artifact.new(:name=>"abc", :id => 1), Artifact.new(:name=>"def", :id => 2) ])
      @service.artifacts.should == { :artifacts => [ {:name=>"abc", :id=>1 }, {:name=>"def", :id=>2}] }
    end

    it "should execute deploy" do
      cmd = mock(JBossAS::DeployCommand)
      cmd.should_receive(:execute).with( "artifact" ).and_return( { :state => :stopped } )

      JBossAS::DeployCommand.should_receive(:new).with(@service, :log => @log).and_return(cmd)

      @service.deploy( "artifact" ).should == { :state => :stopped }
    end

    it "should execute undeploy" do
      cmd = mock(JBossAS::UndeployCommand)
      cmd.should_receive(:execute).with( 'name.war' ).and_return( { :state => :stopped } )

      JBossAS::UndeployCommand.should_receive(:new).with(@service, :log => @log).and_return(cmd)

      @service.undeploy( 'name.war' ).should == { :state => :stopped }
    end

    describe 'status' do
      it "should check the actual jboss_as status" do
        status_command = mock(CheckStatusCommand)
        status_command.should_receive(:execute)
        CheckStatusCommand.should_receive(:new).and_return(status_command)
        @service.status
      end
    end

    describe 'deploy_path' do
      it "should return the path for a given filename" do
        @service.deploy_path('blah.war').should == "#{JBossASService::JBOSS_AS_HOME}/server/#{@service.jboss_as_configuration}/deploy/blah.war"
      end
    end


    describe "tail_command_options" do
      it "should return the path to the log dir" do
        @service.tail_command_options[:log_dir].should == "/opt/jboss-as/server/cluster-ec2/log"
      end
    end
  end
end

