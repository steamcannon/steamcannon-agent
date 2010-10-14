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

require 'sc-agent/services/mod_cluster/mod-cluster-service'
require 'openhash/openhash'

module SteamCannon
  describe ModClusterService do

    before(:each) do
      @db   = mock(DBHelper)
      @log  = Logger.new('/dev/null')
      ServiceManager.should_receive(:register).and_return( @db )
      @service = ModClusterService.new( :log => @log  )
    end

    it "should return status" do
      @service.status.should == { :state => :started }
    end

    it "should not return the selected artifact because of unexpected error" do
      @db.should_receive(:artifact).with( 1 ).and_raise("boom")

      begin
        @cmd.execute( @service.artifact( "1" ) )
        raise "Should raise"
      rescue => e
        e.message.should == "Could not retrieve artifact with id = 1"
      end
    end

    it "should not return the selected artifact" do
      @db.should_receive(:artifact).with( 1 ).and_return( nil )

      begin
        @cmd.execute( @service.artifact( "1" ) )
        raise "Should raise"
      rescue => e
        e.message.should == "Could not retrieve artifact with id = 1"
      end
    end

    it "should return the selected artifact" do
      artifact = mock(Artifact)

      artifact.should_receive(:name).and_return('name')
      artifact.should_receive(:type).and_return('abc')
      artifact.should_receive(:size).and_return(1234)

      @db.should_receive(:artifact).with( 1 ).and_return( artifact )
      @service.artifact( "1" ).should == {:type => 'abc', :name => 'name', :size => 1234 }
    end

    it "should execute configure" do
      @service.should_receive(:change_state).with( [:started,:stopped], :configuring, @service.status[:state] ).and_return( { :state => @service.status[:state] } )
      @service.configure(:a=>:b).should == { :state => @service.status[:state] }
    end

    it "should execute start" do
      @service.should_receive(:change_state).with( [:stopped], :starting, :started ).and_return( { :state => :started } )
      @service.start.should == { :state => :started }
    end

    it "should execute stop" do
      @service.should_receive(:change_state).with( [:started], :stopping, :stopped ).and_return( { :state => :stopped } )
      @service.stop.should == { :state => :stopped }
    end

    it "should execute restart" do
      @service.should_receive(:change_state).with( [:started, :stopped], :restarting, :started ).and_return( { :state => :started } )
      @service.restart.should == { :state => :started }
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
      artifact = {:filename=>"artifact", :tempfile=>"/foo/bar", :type=>"Foobar File"}
      mock_artifact = mock(Artifact)
      @db.should_receive(:save_artifact).with( {:name => artifact[:filename], :location => "/opt/mockservice/deploy/#{artifact[:filename]}", :size => artifact[:tempfile].size, :type => artifact[:type]} ).and_return( mock_artifact )
      @service.deploy( artifact ).should == { :artifact_id => mock_artifact.id }
    end

    it "should execute undeploy" do
      @db.should_receive(:remove_artifact).with( 1 ).and_return( true )
      @service.undeploy( 1 )
    end

  end
end

