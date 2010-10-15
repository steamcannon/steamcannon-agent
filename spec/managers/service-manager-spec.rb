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

require 'sc-agent/managers/service-manager'

module SteamCannon
  describe ServiceManager do

    before(:each) do
      @log  = Logger.new('/dev/null')

      @config = {'services' => 'Mock'}
      @manager = ServiceManager.prepare( @config, @log )
      @ssl_helper = @manager.ssl_helper
    end

    it "should prepare ServiceManager" do
      config = {'services' => 'Mock'}

      Dir.should_receive(:glob).with("lib/sc-agent/services/**/*-service.rb").and_return(['lib/abc/test.rb'])
      ServiceManager.should_receive(:require).with('abc/test')

      ssl_helper = mock(SSLHelper)
      ssl_helper.should_receive(:ssl_files_exists?).and_return(true)

      SSLHelper.should_receive(:new).with( config, :log => @log  ).and_return( ssl_helper )

      ServiceManager.prepare( config, @log )
      ServiceManager.is_configured.should == true
    end

    it "should register a service and return valid db_helper" do
      service = mock('MockService')
      db_helper = mock(DBHelper)

      DBHelper.should_receive(:new).with('mock', :log => @log ).and_return(db_helper)

      @manager.register( service, 'mock', 'Mock Service' ).should == db_helper
      @manager.services.size.should == 1
      @manager.services.should == {"mock"=>{:info=>{:name=>"mock", :full_name=>"Mock Service"}, :object=> service } }
    end

    it "should load services" do
      config = {'services' => 'Mock'}

      service = mock('MockService')
      service.should_receive(:new).with( :log => @log, :config => config )

      @manager.should_receive(:eval).with("SteamCannon::MockService").and_return(service)
      @manager.load_services
    end

    it "should get empty array as services info" do
      @manager.services_info.should == []
    end

    it "should get false because service doesn't exists" do
      @manager.service_exists?( 'abc' ).should == false
    end

    it "should get true because service exists" do
      services = mock('services')
      keys = {"jboss_as" => {}, "abc" => {}}
      services.should_receive(:keys).and_return(keys)

      @manager.services = services

      @manager.service_exists?( 'abc' ).should == true
    end

    it "should get array of services info" do
      DBHelper.stub!(:new)

      service1 = mock('service')
      service2 = mock('service')

      @manager.register(service1, 'service1', 'Mock One Service')
      @manager.register(service2, 'service2', 'Mock Two Service')

      @manager.services_info.size.should == 2
      @manager.services_info.should == [{:name=>"service1", :full_name=>"Mock One Service"}, {:name=>"service2", :full_name=>"Mock Two Service"}]
    end

    describe "configure" do
      before(:each) do
        @ssl_helper.stub!(:store_cert_file)
        @ssl_helper.stub!(:store_key_file)

        @manager.stub!(:fork)
        Process.stub!(:detach)
      end

      it "should configure the agent" do
        @ssl_helper.should_receive(:store_cert_file).with('CERT')
        @ssl_helper.should_receive(:store_key_file).with('KEY')

        @manager.configure( 'CERT', 'KEY' )
      end

      it "should fork and detach child process for restarting" do
        @manager.should_receive(:fork).and_return(1)
        Process.should_receive(:detach).with(1)

        @manager.configure( 'CERT', 'KEY' )
      end
    end

    describe '.execute_operation' do
      it "should not execute the operation because service doesn't support the call" do
        services = mock('services')
        @manager.services = services

        service = mock('MockService')
        service.should_receive(:respond_to?).with('status').and_return(false)
        service.should_not_receive(:send)

        service_info = mock('service_info')
        service_info.should_receive(:[]).with(:object).and_return( service )

        services.should_receive(:[]).with('mock').and_return( service_info )

        begin
          @manager.execute_operation( 'mock', 'status' )
          raise "This shouldn't be executed"
        rescue => e
          e.message.should == "Operation 'status' is not supported in Spec::Mocks::Mock service"
        end
      end

      it "should not execute the operation because parameters count isn't same" do
        services = mock('services')
        @manager.services = services

        method = mock('method')
        method.should_receive(:arity).exactly(3).times.and_return(2)

        service = mock('MockService')
        service.should_receive(:respond_to?).with('status').and_return(true)
        service.should_receive(:method).exactly(3).times.and_return( method )
        service.should_not_receive(:send)

        service_info = mock('service_info')
        service_info.should_receive(:[]).with(:object).and_return( service )

        services.should_receive(:[]).with('mock').and_return( service_info )

        begin
          @manager.execute_operation( 'mock', 'status', 'a' )
          raise "This shouldn't be executed"
        rescue => e
          e.message.should == "Operation 'status' takes 2 arguments, but provided 1"
        end
      end

      it "should execute operation on service without params" do
        services = mock('services')

        service = mock('MockService')
        service.should_receive(:respond_to?).with('status').and_return(true)
        service.should_receive(:send).with('status')

        service_info = mock('service_info')
        service_info.should_receive(:[]).with(:object).and_return( service )

        services.should_receive(:[]).with('mock').and_return( service_info )

        @manager.services = services
        @manager.execute_operation( 'mock', 'status' )
      end

      it "should execute operation on service with two params" do
        services = mock('services')

        method = mock('method')
        method.should_receive(:arity).and_return(2)

        service = mock('MockService')
        service.should_receive(:respond_to?).with('status').and_return(true)
        service.should_receive(:method).and_return( method )

        service.should_receive(:send).with('status', 'a', 'b')

        service_info = mock('service_info')
        service_info.should_receive(:[]).with(:object).and_return( service )

        services.should_receive(:[]).with('mock').and_return( service_info )

        @manager.services = services
        @manager.execute_operation( 'mock', 'status', "a", "b" )
      end
    end
  end
end

