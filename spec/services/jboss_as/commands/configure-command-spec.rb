require 'ct-agent/services/jboss_as/commands/configure-command'

module CoolingTower
  describe ConfigureCommand do

    before(:each) do
      @service        = mock( 'Service' )

      @service.should_receive(:state).and_return( :stopped )

      @log            = Logger.new('/dev/null')
      @cmd            = ConfigureCommand.new( @service, :log => @log )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
    end

    it "should not configure because of wrong state" do
      @cmd.instance_variable_set(:@state, :starting)

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :configure, :started ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      db2 = mock("db2")
      db2.should_receive( :save_event ).with( :configure, :failed, :msg=>"Service is currently in 'starting' state. It needs to be in 'started' or 'stopped' state to execute this action." )
      @service.should_receive(:db).and_return( db2 )

      @cmd.execute( {}.to_json ).should == {:msg=>"Service is currently in 'starting' state. It needs to be in 'started' or 'stopped' state to execute this action.", :status=>"error"}
    end

    it "should not configure because of invalid data provided" do
      @service.instance_variable_set(:@state, :stopped)

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :configure, :started ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      db2 = mock("db2")
      db2.should_receive( :save_event ).with( :configure, :failed, :msg => "No or invalid data provided to configure service." )
      @service.should_receive(:db).and_return( db2 )

      @cmd.execute( nil ).should == { :msg => "No or invalid data provided to configure service.", :status => "error"}
    end

    it "should configure service" do
      @service.instance_variable_set(:@state, :stopped)

      db1 = mock("db1")
      db1.should_receive( :save_event ).with( :configure, :started ).and_return("1")
      @service.should_receive(:db).and_return( db1 )

      @service.should_receive(:state=).with(:updating)
      @service.should_receive(:state).and_return(:stopped)

      @cmd.should_receive( :configure ).with( {}, "1" )

      @cmd.execute( {}.to_json ).should == { :status => "ok", :response => { :state => :stopped } }
    end

    describe ".update" do
      it "should do nothing" do

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :configure, :finished )
        @service.should_receive(:db).and_return( db1 )

        @service.should_receive(:state=).with(:stopped)

        UpdateGossipHostAddressCommand.should_not_receive(:new)
        UpdateS3PingCredentialsCommand.should_not_receive(:new)
        UpdateProxyListCommand.should_not_receive(:new)

        RestartCommand.should_not_receive(:new)
        StartCommand.should_not_receive(:new)

        @cmd.configure( {}, "1" )
      end

      it "should update gossip host only" do
        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :configure, :finished )
        @service.should_receive(:db).and_return( db1 )

        cmd = mock(UpdateGossipHostAddressCommand)
        cmd.should_receive( :execute ).with( "10.1.0.1" ).and_return( false )

        UpdateGossipHostAddressCommand.should_receive(:new).with( :log => @log ).and_return( cmd )

        UpdateS3PingCredentialsCommand.should_not_receive(:new)
        UpdateProxyListCommand.should_not_receive(:new)
        RestartCommand.should_not_receive(:new)
        StartCommand.should_not_receive(:new)

        @service.should_receive(:state=).with(:stopped)

        @cmd.configure( { :gossip_host => "10.1.0.1" }, "1" )
      end

      it "should update gossip host and s3_ping, but restart isn't executed because we're in 'stopped' state" do
        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :configure, :finished )
        @service.should_receive(:db).and_return( db1 )

        gossip_host_cmd = mock(UpdateGossipHostAddressCommand)
        gossip_host_cmd.should_receive( :execute ).with( "10.1.0.1" ).and_return( false )

        UpdateGossipHostAddressCommand.should_receive(:new).with( :log => @log ).and_return( gossip_host_cmd )

        s3_ping_cmd = mock(UpdateS3PingCredentialsCommand)
        s3_ping_cmd.should_receive( :execute ).with( { 'access_key' => 'a', 'secret_access_key' => 'b', 'bucket' => 'c'} ).and_return( true )

        UpdateS3PingCredentialsCommand.should_receive(:new).with( :log => @log ).and_return( s3_ping_cmd )

        UpdateProxyListCommand.should_not_receive(:new)
        RestartCommand.should_not_receive(:new)
        StartCommand.should_not_receive(:new)

        @service.should_receive(:state=).ordered.with(:stopped)

        @cmd.configure( { :gossip_host => "10.1.0.1", :s3_ping => { 'access_key' => 'a', 'secret_access_key' => 'b', 'bucket' => 'c'} }, "1" )
      end

      it "should update proxy_list and start JBoss AS" do
        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :configure, :finished )
        @service.should_receive(:db).and_return( db1 )

        proxy_list_cmd = mock(UpdateProxyListCommand)
        proxy_list_cmd.should_receive( :execute ).with( { "10.1.0.1" => { :host => "10.1.0.1", :port => 80 } } ).and_return( true )

        UpdateProxyListCommand.should_receive(:new).with( :log => @log ).and_return( proxy_list_cmd )

        start_cmd = mock(StartCommand)
        start_cmd.should_receive(:execute).with( "1" ).and_return( :status => 'ok' )

        StartCommand.should_receive(:new).with( @service ).and_return( start_cmd )

        restart_cmd = mock(RestartCommand)
        restart_cmd.should_receive(:execute).with( "1" ).and_return( :status => 'ok' )

        RestartCommand.should_receive(:new).with( @service ).and_return( restart_cmd )

        @service.should_receive(:state=).ordered.with(:started)

        @cmd.configure( {:proxy_list => { "10.1.0.1" => { :host => "10.1.0.1", :port => 80 } } }, "1" )
      end
    end

  end
end

