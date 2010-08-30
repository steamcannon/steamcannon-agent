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

require 'ct-agent/managers/service-manager'

module CoolingTower
  describe ServiceManager do

    before(:each) do
      @log  = Logger.new('/dev/null')

      config = {'services' => 'Mock'}
      @manager = ServiceManager.prepare( config, @log )
    end

    it "should prepare ServiceManager" do
      config = {'services' => 'Mock'}

      Dir.should_receive(:glob).with("lib/ct-agent/services/**/*-service.rb").and_return(['lib/abc/test.rb'])
      @manager.should_receive(:require).with('abc/test')

      @manager.prepare( config, @log )
    end

    it "should register a service and return valid db_helper" do
      service = mock('MockService')
      db_helper = mock(DBHelper)

      DBHelper.should_receive(:new).with('mock', :log => @log ).and_return(db_helper)

      @manager.register( service, 'Mock Service' ).should == db_helper
      @manager.services.size.should == 1
      @manager.services.should == {"mock"=>{:info=>{:name=>"mock", :full_name=>"Mock Service"}, :object=> service } }
    end

    it "should load services" do
      config = {'services' => 'Mock'}

      service = mock('MockService')
      service.should_receive(:new).with( :log => @log, :config => config )

      @manager.should_receive(:eval).with("CoolingTower::MockService").and_return(service)
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
      services.should_receive(:[]).with(:abc).and_return('abc')

      @manager.services = services

      @manager.service_exists?( 'abc' ).should == true
    end

    it "should get array of services info" do
      DBHelper.stub!(:new)

      service1 = mock('MockOneService')
      service2 = mock('MockTwoService')

      class1_mock = mock(Class)
      class1_mock.should_receive(:name).and_return('MockOneService')

      service1.should_receive(:class).twice.and_return(class1_mock)

      class2_mock = mock(Class)
      class2_mock.should_receive(:name).and_return('MockTwoService')

      service2.should_receive(:class).twice.and_return(class2_mock)

      @manager.register(service1, 'Mock One Service')
      @manager.register(service2, 'Mock Two Service')

      @manager.services_info.size.should == 2
      @manager.services_info.should == [{:name=>"mock_two", :full_name=>"Mock Two Service"}, {:name=>"mock_one", :full_name=>"Mock One Service"}]
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

        @manager.execute_operation( 'mock', 'status' )
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

        @manager.execute_operation( 'mock', 'status', 'a' )
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

