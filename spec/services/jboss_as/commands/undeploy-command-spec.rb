require 'sc-agent/services/jboss_as/commands/undeploy-command'

module SteamCannon
  describe UndeployCommand do

    before(:each) do
      @service        = mock( 'Service' )
      @service_helper = mock( ServiceHelper )

      @db = mock("DB")

      @service.stub!( :service_helper ).and_return( @service_helper )
      @service.stub!(:db).and_return( @db )

      @service.should_receive(:state).and_return( :stopped )

      @log            = Logger.new('/dev/null')
      @cmd            = UndeployCommand.new( @service, :log => @log )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
    end

    it "should remove the artifact" do
      @db.should_receive( :save_event ).with( :undeploy, :started ).and_return("1")

      artifact = mock(Artifact)
      artifact.should_receive( :location ).and_return("this/is/a/location")

      @db.should_receive( :artifact ).with( 12 ).and_return( artifact )
      @db.should_receive( :remove_artifact ).with( 12 ).and_return(true)

      @db.should_receive( :save_event ).with( :undeploy, :finished, :parent => "1" )

      FileUtils.should_receive(:rm).with("this/is/a/location", :force => true)

      @cmd.execute( 12 ).should == nil
    end

    it "should return error message when artifact doesn't exists" do
      @db.should_receive( :save_event ).with( :undeploy, :started ).and_return("1")

      @db.should_receive( :artifact ).with( 12 ).and_return( false )
      @db.should_receive( :save_event ).with( :undeploy, :failed, :parent => "1", :msg=>"Artifact with id '12' not found" )

      begin
        @cmd.execute( 12 )
        raise "Should raise"
      rescue => e
        e.message.should == "Artifact with id '12' not found"
      end
    end

    it "should return error message when invalid artifact_id is provided" do
      @db.should_receive( :save_event ).with( :undeploy, :started ).and_return("1")
      @db.should_receive( :save_event ).with( :undeploy, :failed, :parent => "1", :msg=>"No or invalid artifact id provided" )

      begin
        @cmd.execute( "d24" )
        raise "Should raise"
      rescue => e
        e.message.should == "No or invalid artifact id provided"
      end
    end
  end
end

