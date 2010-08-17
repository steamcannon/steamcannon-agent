require 'ct-agent/services/jboss_as/jboss-as-service'
require 'ct-agent/helpers/db-helper'

module CoolingTower
  describe JBossASService do

    before(:each) do

      @db = mock(DBHelper)

      ServiceManager.should_receive(:register).and_return( @db )

      @service        = JBossASService.new( :log => Logger.new('/dev/null') )
      @exec_helper    = @service.instance_variable_get(:@exec_helper)
    end

    #
    # RESTART
    #

    it "should restart JBoss AS service" do
      @db.should_receive( :save_event ).with( :restart, :received ).and_return("1")
      @service.should_receive(:manage_service).with( :restart, "1", :stopped, :started, true )
      @service.restart.should == { :status => 'ok', :response => { :status => :restarting } }
    end

    it "should not restart JBoss AS service because service is in wrong state" do
      @service.instance_variable_set(:@status, :stopping)

      @db.should_receive( :save_event ).with( :restart, :received ).and_return("1")
      @db.should_receive( :save_event ).with( :restart, :failed, "1", "Current service status ('stopping') does not allow restarting." )

      @service.should_not_receive( :manage_service )

      @service.restart.should == { :status => 'error', :msg => "Current service status ('stopping') does not allow restarting." }
    end

    #
    # STOP
    #

    it "should stop JBoss AS service" do
      @service.instance_variable_set(:@status, :started)

      @db.should_receive( :save_event ).with( :stop, :received ).and_return("1")
      @service.should_receive(:manage_service).with( :stop, "1", :started, :stopped, true )
      @service.stop.should == { :status => 'ok', :response => { :status => :stopping } }
    end

    it "should not stop JBoss AS service because of wrong state" do
      @service.instance_variable_set(:@status, :starting)

      @db.should_receive( :save_event ).with( :stop, :received ).and_return("1")
      @db.should_receive( :save_event ).with( :stop, :failed, "1", "JBoss is currently in 'starting' state. It needs to be in 'started' state to execute this action." )
      @service.should_not_receive( :manage_service )
      @service.stop.should == { :status => 'error', :msg => "JBoss is currently in 'starting' state. It needs to be in 'started' state to execute this action." }
    end

    it "should not stop JBoss AS service because it is already stopped" do
      @service.instance_variable_set(:@status, :stopped)

      @db.should_receive( :save_event ).with( :stop, :received ).and_return("1")
      @db.should_receive( :save_event ).with( :stop, :finished, "1" )
      @service.should_not_receive( :manage_service )
      @service.stop.should == {:status=>"ok", :response=>{:status=>:stopped}}
    end

    #
    # START
    #

    it "should start JBoss AS service" do
      @service.instance_variable_set(:@status, :stopped)

      @db.should_receive( :save_event ).with( :start, :received ).and_return("1")
      @service.should_receive(:manage_service).with( :start, "1", :stopped, :started, true )
      @service.start.should == { :status => 'ok', :response => { :status => :starting } }
    end

    it "should not start JBoss AS service because of wrong state" do
      @service.instance_variable_set(:@status, :starting)

      @db.should_receive( :save_event ).with( :start, :received ).and_return("1")
      @db.should_receive( :save_event ).with( :start, :failed, "1", "JBoss is currently in 'starting' state. It needs to be in 'stopped' state to execute this action." )
      @service.should_not_receive( :manage_service )
      @service.start.should == { :status => 'error', :msg => "JBoss is currently in 'starting' state. It needs to be in 'stopped' state to execute this action." }
    end

    it "should not start JBoss AS service because it is already started" do
      @service.instance_variable_set(:@status, :started)

      @db.should_receive( :save_event ).with( :start, :received ).and_return("1")
      @db.should_receive( :save_event ).with( :start, :finished, "1" )
      @service.should_not_receive( :manage_service )
      @service.start.should == {:status=>"ok", :response=>{:status=>:started}}
    end
  end
end

