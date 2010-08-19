require 'ct-agent/services/commands/restart-command'

module CoolingTower
  describe RestartCommand do

    def prepare_cmd( state )
      @service        = mock( 'Service' )

      @service.should_receive(:state).and_return( state )

      @cmd            = RestartCommand.new( @service, :log => Logger.new('/dev/null') )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
    end

    it "should restart the service" do
      prepare_cmd( :started )

      db1 = mock("db0")
      db1.should_receive( :save_event ).with( :restart, :started, :parent => nil ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      @cmd.should_receive(:restart).with( nil )

      @service.should_receive(:name).and_return( 'jboss-as6' )
      @service.should_receive(:state=).with(:restarting)
      @service.should_receive(:state).and_return( :restarting )

      @cmd.execute.should == { :status => 'ok', :response => { :state => :restarting } }
    end

    it "should not restart service because service is in wrong state" do
      prepare_cmd( :stopping )

      db = mock("db")
      db.should_receive( :save_event ).with( :restart, :started, :parent => nil ).and_return("1")

      @service.should_receive(:db).and_return( db )

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :restart, :failed, :parent => nil, :msg => "Current service status ('stopping') does not allow to restart the service." ).and_return("1")

      @service.should_receive(:db).and_return( db1 )

      @cmd.execute.should == { :status => 'error', :msg => "Current service status ('stopping') does not allow to restart the service." }
    end

    describe ".restart" do
      it "should restart service" do
        prepare_cmd( :started )

        @service.should_receive(:name).and_return( 'jboss-as6' )
        @exec_helper.should_receive(:execute).with("service jboss-as6 restart")
        @service.should_receive(:state=).with(:started)

        db2 = mock("db2")
        db2.should_receive( :save_event ).with( :restart, :finished, :parent => nil ).and_return("1")
        @service.should_receive(:db).and_return( db2 )

        @cmd.restart( nil ).should == true
      end
    end
  end
end

