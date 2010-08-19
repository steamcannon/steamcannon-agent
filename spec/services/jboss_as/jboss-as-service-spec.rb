# JBoss, Home of Professional Open Source
# Copyright 2009, Red Hat Middleware LLC, and individual contributors
# by the @authors tag. See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
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

require 'ct-agent/services/jboss_as/jboss-as-service'

module CoolingTower
  describe JBossASService do

    before(:each) do
      @db   = mock(DBHelper)
      @log  = Logger.new('/dev/null')

      ServiceManager.should_receive(:register).and_return( @db )

      @service        = JBossASService.new( :log => @log  )
      @exec_helper    = @service.instance_variable_get(:@exec_helper)
    end

    it "should return status" do
      @service.status.should == { :status => "ok", :response => { :state => :stopped } }
    end

    it "should execute configure" do
      cmd = mock(ConfigureCommand)
      cmd.should_receive(:execute).with( :a => :b ).and_return( { :status => "ok", :response => { :state => :stopped } } )

      ConfigureCommand.should_receive(:new).with( @service, :log => @log, :threaded => true ).and_return( cmd )

      @service.configure( :a => :b ).should == { :status => "ok", :response => { :state => :stopped } }
    end

    it "should execute start" do
      cmd = mock(StartCommand)
      cmd.should_receive(:execute).with( no_args ).and_return( { :status => "ok", :response => { :state => :starting } } )

      StartCommand.should_receive(:new).with( @service, :log => @log, :threaded => true ).and_return( cmd )

      @service.start.should == { :status => "ok", :response => { :state => :starting } }
    end

    it "should execute stop" do
      cmd = mock(StopCommand)
      cmd.should_receive(:execute).with( no_args ).and_return( { :status => "ok", :response => { :state => :stopping } } )

      StopCommand.should_receive(:new).with( @service, :log => @log, :threaded => true ).and_return( cmd )

      @service.stop.should == { :status => "ok", :response => { :state => :stopping } }
    end

    it "should execute restart" do
      cmd = mock(RestartCommand)
      cmd.should_receive(:execute).with( no_args ).and_return( { :status => "ok", :response => { :state => :restarting } } )

      RestartCommand.should_receive(:new).with( @service, :log => @log, :threaded => true ).and_return( cmd )

      @service.restart.should == { :status => "ok", :response => { :state => :restarting } }
    end
  end
end

