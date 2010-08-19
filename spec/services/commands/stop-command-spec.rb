require 'ct-agent/services/commands/stop-command'

module CoolingTower
  describe StopCommand do

    def prepare_cmd( state )
      @service        = mock( 'Service' )

      @service.should_receive(:state).and_return( state )

      @cmd            = StopCommand.new( @service, :log => Logger.new('/dev/null') )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
    end

    it "should stop JBoss AS service" do
      prepare_cmd( :started )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :stop, :started, :parent => nil ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      @cmd.should_receive(:stop).with( nil )

      @service.should_receive(:name).and_return( 'jboss-as6' )
      @service.should_receive(:state=).with(:stopping)
      @service.should_receive(:state).and_return( :stopping )

      @cmd.execute.should == { :status => 'ok', :response => { :state => :stopping } }
    end

    it "should not stop service because of wrong state" do
      prepare_cmd( :stopping )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :stop, :started, :parent => nil ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :stop, :failed, :parent => nil, :msg => "Current service status ('stopping') does not allow to stop the service." ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      @cmd.execute.should == { :status => 'error', :msg => "Current service status ('stopping') does not allow to stop the service." }
    end

    it "should not stop service because it is already stopped" do
      prepare_cmd( :stopped )
      @cmd.execute.should == { :status => 'ok', :response => { :state => :stopped } }
    end

    describe ".stop" do
      it "should stop service" do
        prepare_cmd( :started )

        @service.should_receive(:name).and_return( 'jboss-as6' )

        @exec_helper.should_receive(:execute).with('service jboss-as6 stop')

        @service.should_receive(:state=).with(:stopped)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :stop, :finished, :parent => nil ).and_return("1")
        @service.should_receive(:db).and_return( db1 )

        @cmd.stop( nil ) == true
      end

      it "should try to stop the service but fail returning false" do
        prepare_cmd( :started )

        @service.should_receive(:name).twice.and_return( 'jboss-as6' )

        @exec_helper.should_receive(:execute).with('service jboss-as6 stop').and_raise("aaa")

        @service.should_receive(:state=).with(:started)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :stop, :failed, :parent => nil, :msg => "An error occurred while stopping 'jboss-as6' service" )
        @service.should_receive(:db).and_return( db1 )

        @cmd.stop( nil ) == false
      end
    end
  end
end

