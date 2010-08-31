require 'sc-agent/services/jboss_as/commands/deploy-command'

module SteamCannon
  describe DeployCommand do

    before(:each) do
      @service        = mock( 'Service' )
      @service_helper = mock( ServiceHelper )

      @db = mock("DB")

      @service.stub!( :service_helper ).and_return( @service_helper )
      @service.stub!(:db).and_return( @db )

      @service.should_receive(:state).and_return( :stopped )

      @log            = Logger.new('/dev/null')
      @cmd            = DeployCommand.new( @service, :log => @log )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
    end

    it "should not deploy an artifact because it is in wrong format" do
      @db.should_receive( :save_event ).with( :deploy, :started ).and_return("1")
      @db.should_receive( :save_event ).with( :deploy, :failed, :msg => "No or invalid artifact provided", :parent=>"1" )

      @cmd.execute( {} ).should == {:msg=>"No or invalid artifact provided", :status=>"error"}
    end

    it "should not deploy an artifact because no artifact was provided" do
      @db.should_receive( :save_event ).with( :deploy, :started ).and_return("1")
      @db.should_receive( :save_event ).with( :deploy, :failed, :msg => "No or invalid artifact provided", :parent=>"1" )

      @cmd.execute( nil ).should == {:msg=>"No or invalid artifact provided", :status=>"error"}
    end

    it "should deploy an artifact" do
      @db.should_receive( :save_event ).with( :deploy, :started ).and_return("1")

      @service.should_receive(:jboss_as_configuration).and_return("default")

      artifact = mock(Artifact)
      artifact.should_receive(:id).and_return(1)

      @db.should_receive( :save_artifact ).with( :type=>"application/json", :name=>"name.war", :size=>1234, :location=>"/opt/jboss-as/server/default/deploy/name.war" ).and_return( artifact )

      file = mock("File")
      file.should_receive(:size).and_return(1234)

      File.should_receive(:open)
      FileUtils.should_receive(:mv)
      FileUtils.should_receive(:mkdir_p).with("/opt/jboss-as/tmp")

      @db.should_receive( :save_event ).with( :deploy, :finished, :parent=>"1" )

      @cmd.execute( { :filename => "name.war", :tempfile => file, :type => "application/json" } ).should == {:status=>"ok", :response=>{:artifact_id=>1}}
    end

    it "should gracefully handle error while saving artifact" do
      @db.should_receive( :save_event ).with( :deploy, :started ).and_return("1")

      @service.should_receive(:jboss_as_configuration).and_return("default")
      @db.should_receive( :save_artifact ).with( :type=>"application/json", :name=>"name.war", :size=>1234, :location=>"/opt/jboss-as/server/default/deploy/name.war" )

      FileUtils.should_receive(:mkdir_p).with("/opt/jboss-as/tmp")

      file = mock("File")
      file.should_receive(:size).and_return(1234)

      @db.should_receive( :save_event ).with( :deploy, :failed, :parent=>"1" )

      @cmd.execute( { :filename => "name.war", :tempfile => file, :type => "application/json" } ).should == {:msg=>"Error while saving artifact name.war", :status=>"error"}
    end
  end
end

