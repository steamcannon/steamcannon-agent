# JBoss, Home of Professional Open Source
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

require 'sc-agent/services/postgresql/postgresql-service'
require 'openhash/openhash'

module SteamCannon
  describe PostgreSQLService do

    before(:each) do
      @db             = mock(DBHelper)
      @log            = Logger.new('/dev/null')

      ServiceManager.stub!(:register).and_return(@db)

      @initialize_command = mock(PostgreSQL::InitializeCommand)
      @initialize_command.stub!(:execute)
      PostgreSQL::InitializeCommand.stub!(:new).and_return(@initialize_command)
      
      @service        = PostgreSQLService.new(:log => @log)
      @exec_helper    = @service.instance_variable_get(:@exec_helper)
      @service_helper = @service.instance_variable_get(:@service_helper)
    end

    it "should initialize the db on instantiation" do
      @initialize_command.should_receive(:execute)
      PostgreSQL::InitializeCommand.should_receive(:new).and_return(@initialize_command)
      PostgreSQLService.new
    end

    it "should return started status" do
      @exec_helper.should_receive(:execute).with("service postgresql status").and_return("postmaster (pid 1729 1728 1727 1726 1724 1708) is running...")
      @service.status.should == {:state => :started}
    end

    it "should return stopped status" do
      @exec_helper.should_receive(:execute).with("service postgresql status").and_return("postmaster is stopped")
      @service.status.should == {:state => :stopped}
    end

    it "should return error status" do
      @exec_helper.should_receive(:execute).with("service postgresql status").and_return("bleh blah")
      @service.status.should == {:state => :error}
    end

    it "should restart the service" do
      @service_helper.should_receive(:execute).with(:restart, :backgroud => true).and_return({:state => :restarting})
      @service.restart.should == {:state => :restarting}
    end

    it "should stop the service" do
      @service_helper.should_receive(:execute).with(:stop, :backgroud => true).and_return({:state => :stopping})
      @service.stop.should == {:state => :stopping}
    end

    it "should start the service" do
      @service_helper.should_receive(:execute).with(:start, :backgroud => true).and_return({:state => :starting})
      @service.start.should == {:state => :starting}
    end
  end
end

