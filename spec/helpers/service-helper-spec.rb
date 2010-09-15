require 'sc-agent/helpers/service-helper'

module SteamCannon
  describe ServiceHelper do

    def prepare_cmd( state )
      @service        = mock( 'Service' )

      @service.stub!(:state).and_return( state )
      @service.stub!(:name).and_return( 'jboss-as' )

      @helper         = ServiceHelper.new( @service, :log => Logger.new('/dev/null') )
      @exec_helper    = @helper.instance_variable_get(:@exec_helper)
    end

    ##########################################################
    # START                                                  #
    ##########################################################

    it "should start service" do
      prepare_cmd( :stopped )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :start, :started, :parent => nil ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      @helper.should_receive(:start).with( nil )

      @service.should_receive(:state).ordered.and_return( :stopped )
      @service.should_receive(:state=).ordered.with(:starting)
      @service.should_receive(:state).ordered.and_return( :starting )

      @helper.execute( :start ).should == { :state => :starting }
    end

    it "should not start service because of wrong state" do
      prepare_cmd( :stopping )

      begin
        @helper.execute( :start )
        raise "Should raise"
      rescue => e
        e.message.should == "Current service status ('stopping') does not allow to start the service."
      end
    end

    it "should not start service because it is already started" do
      prepare_cmd( :started )
      @helper.execute( :start ).should == { :state => :started }
    end

    describe ".start" do
      it "should start the service" do
        prepare_cmd( :stopped )

        @exec_helper.should_receive(:execute).with('service jboss-as start')

        @service.should_receive(:state=).with(:started)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :start, :finished, :parent => nil ).and_return("1")
        @service.should_receive(:db).and_return( db1 )

        @helper.start( nil ).should == true
      end

      it "should try to start the service but fail returning false" do
        prepare_cmd( :stopped )

        @helper.instance_variable_set(:@state, :stopped )

        @exec_helper.should_receive(:execute).with('service jboss-as start').and_raise('Abc')

        @service.should_receive(:state=).with(:stopped)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :start, :failed, {:msg=>"An error occurred while starting 'jboss-as' service", :parent=>nil} )
        @service.should_receive(:db).and_return( db1 )

        @helper.start( nil ).should == false
      end
    end

    ##########################################################
    # STOP                                                   #
    ##########################################################

    it "should stop service" do
      prepare_cmd( :started )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :stop, :started, :parent => nil ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      @helper.should_receive(:stop).with( nil )

      @service.should_receive(:state).and_return( :started )
      @service.should_receive(:state=).with(:stopping)
      @service.should_receive(:state).and_return( :stopping )

      @helper.execute( :stop ).should == { :state => :stopping }
    end

    it "should not stop service because of wrong state" do
      prepare_cmd( :stopping )

      begin
        @helper.execute( :stop )
        raise "Should raise"
      rescue => e
        e.message.should == "Current service status ('stopping') does not allow to stop the service."
      end
    end

    it "should not stop service because it is already stopped" do
      prepare_cmd( :stopped )
      @helper.execute( :stop ).should == { :state => :stopped }
    end

    describe ".stop" do
      it "should stop service" do
        prepare_cmd( :started )

        @exec_helper.should_receive(:execute).with('service jboss-as stop')
        @service.should_receive(:state=).with(:stopped)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :stop, :finished, :parent => nil ).and_return("1")
        @service.should_receive(:db).and_return( db1 )

        @helper.stop( nil ) == true
      end

      it "should try to stop the service but fail returning false" do
        prepare_cmd( :started )

        @helper.instance_variable_set(:@state, :started )

        @exec_helper.should_receive(:execute).with('service jboss-as stop').and_raise("aaa")

        @service.should_receive(:state=).with(:started)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :stop, :failed, :parent => nil, :msg => "An error occurred while stopping 'jboss-as' service" )
        @service.should_receive(:db).and_return( db1 )

        @helper.stop( nil ) == false
      end
    end

    ##########################################################
    # RESTART                                                #
    ##########################################################

    it "should restart the service" do
      prepare_cmd( :started )

      db1 = mock("db0")
      db1.should_receive( :save_event ).with( :restart, :started, :parent => nil ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      @helper.should_receive(:restart).with( nil )

      @service.should_receive(:state).and_return( :started )
      @service.should_receive(:state=).with(:restarting)
      @service.should_receive(:state).and_return( :restarting )

      @helper.execute( :restart ).should == { :state => :restarting }
    end

    it "should not restart service because service is in wrong state" do
      prepare_cmd( :stopping )

      begin
        @helper.execute( :restart )
        raise "Should raise"
      rescue => e
        e.message.should == "Current service status ('stopping') does not allow to restart the service."
      end
    end

    describe ".restart" do
      it "should restart service" do
        prepare_cmd( :started )

        @exec_helper.should_receive(:execute).with("service jboss-as restart")
        @service.should_receive(:state=).with(:started)

        db2 = mock("db2")
        db2.should_receive( :save_event ).with( :restart, :finished, :parent => nil ).and_return("1")
        @service.should_receive(:db).and_return( db2 )

        @helper.restart( nil ).should == true
      end
    end
  end
end

