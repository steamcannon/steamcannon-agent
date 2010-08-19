require 'ct-agent/services/commands/start-command'

module CoolingTower
  describe StartCommand do

    def prepare_cmd( state )
      @service        = mock( 'Service' )

      @service.should_receive(:state).and_return( state )

      @cmd            = StartCommand.new( @service, :log => Logger.new('/dev/null') )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
    end

    it "should start service" do
      prepare_cmd( :stopped )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :start, :started, :parent => nil ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      @cmd.should_receive(:start).with( nil )

      @service.should_receive(:name).and_return( 'jboss-as6' )
      @service.should_receive(:state=).with(:starting)
      @service.should_receive(:state).and_return( :starting )

      @cmd.execute.should == { :status => 'ok', :response => { :state => :starting } }
    end

    it "should not start service because of wrong state" do
      prepare_cmd( :stopping )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :start, :started, :parent => nil )
      @service.should_receive(:db).and_return( db1 )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :start, :failed, :parent => nil, :msg => "Current service status ('stopping') does not allow to start the service." )
      @service.should_receive(:db).and_return( db1 )

      @cmd.execute.should == { :status => 'error', :msg => "Current service status ('stopping') does not allow to start the service." }
    end

    it "should not start service because it is already started" do
      prepare_cmd( :started )

      @cmd.execute.should == { :status => 'ok', :response => { :state => :started } }
    end

    describe ".start" do
      it "should start the service" do
        prepare_cmd( :stopped )

        @service.should_receive(:name).and_return( 'jboss-as6' )
        @exec_helper.should_receive(:execute).with('service jboss-as6 start')

        @service.should_receive(:state=).with(:started)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :start, :finished, :parent => nil ).and_return("1")
        @service.should_receive(:db).and_return( db1 )

        @cmd.start( nil ).should == true
      end

      it "should try to start the service but fail returning false" do
        prepare_cmd( :stopped )

        @service.should_receive(:name).twice.and_return( 'jboss-as6' )
        
        @exec_helper.should_receive(:execute).with('service jboss-as6 start').and_raise('Abc')

        @service.should_receive(:state=).with(:stopped)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :start, :failed, {:msg=>"An error occurred while starting 'jboss-as6' service", :parent=>nil} )
        @service.should_receive(:db).and_return( db1 )

        @cmd.start( nil ).should == false
      end
    end
  end
end

