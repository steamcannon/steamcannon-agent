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

      begin
        @cmd.execute( {} )
        raise "Should raise"
      rescue => e
        e.message.should == "No or invalid artifact provided"
      end
    end

    it "should not deploy an artifact because no artifact was provided" do
      @db.should_receive( :save_event ).with( :deploy, :started ).and_return("1")
      @db.should_receive( :save_event ).with( :deploy, :failed, :msg => "No or invalid artifact provided", :parent=>"1" )

      begin
        @cmd.execute( nil )
        raise "Should raise"
      rescue => e
        e.message.should == "No or invalid artifact provided"
      end
    end

    it "should deploy an artifact" do
      @db.should_receive( :save_event ).with( :deploy, :started ).and_return("1")

      @service.should_receive(:deploy_path).with('name.war').and_return("/opt/jboss-as/server/default/deploy/name.war")

      artifact = mock(Artifact)
      artifact.should_receive(:id).and_return(1)

      @db.should_receive( :save_artifact ).with( :type=>"application/json", :name=>"name.war", :size=>1234, :location=>"/opt/jboss-as/server/default/deploy/name.war" ).and_return( artifact )

      file = mock("File")
      file.should_receive(:size).and_return(1234)

      File.should_receive(:open)
      FileUtils.should_receive(:mv)
      FileUtils.should_receive(:mkdir_p).with("/opt/jboss-as/tmp")

      @db.should_receive( :save_event ).with( :deploy, :finished, :parent=>"1" )

      @cmd.execute( { :filename => "name.war", :tempfile => file, :type => "application/json" } ).should == { :artifact_id=>1 }
    end

    it "should gracefully handle error while saving artifact" do
      @db.should_receive( :save_event ).with( :deploy, :started ).and_return("1")

      @service.should_receive(:deploy_path).with('name.war').and_return("/opt/jboss-as/server/default/deploy/name.war")
      @db.should_receive( :save_artifact ).with( :type=>"application/json", :name=>"name.war", :size=>1234, :location=>"/opt/jboss-as/server/default/deploy/name.war" )

      FileUtils.should_receive(:mkdir_p).with("/opt/jboss-as/tmp")

      file = mock("File")
      file.should_receive(:size).and_return(1234)

      @db.should_receive( :save_event ).with( :deploy, :failed, :parent=>"1", :msg => "Error while saving artifact name.war" )

      begin
        @cmd.execute( { :filename => "name.war", :tempfile => file, :type => "application/json" } )
        raise "Should raise"
      rescue => e
        e.message.should == "Error while saving artifact name.war"
      end
    end

    describe "is_artifact_pull_url?" do
      it "should return false if artifact_location is nil" do
        @cmd.should_receive(:artifact_location).with('artifact').and_return(nil)
        @cmd.is_artifact_pull_url?('artifact').should be(false)
      end

      it "should return true if artifact_location is not nil" do
        @cmd.should_receive(:artifact_location).with('artifact').and_return('over there')
        @cmd.is_artifact_pull_url?('artifact').should be(true)
      end
    end

    describe "artifact_location" do
      it "should return nil if artifact is nil" do
        @cmd.artifact_location(nil).should be(nil)
      end

      it "should return nil if artifact is a file upload" do
        @cmd.artifact_location({}).should be(nil)
      end

      it "should return nil if invalid json" do
        @cmd.artifact_location('invalid json').should be(nil)
      end

      it "should return location if valid json and has :location key" do
        json = { :location => 'over there' }.to_json
        @cmd.artifact_location(json).should == 'over there'
      end
    end

    describe "pull_artifact" do
      before(:each) do
        @uri = mock('uri')
        @uri.stub!(:path).and_return('/path/to/artifact.war')
        @tempfile = mock('tempfile')
        @tempfile.stub!(:base_uri).and_return(@uri)
        @tempfile.stub!(:content_type).and_return('content_type')
        @artifact = mock('artifact')
        @cmd.stub!(:artifact_location).and_return('location')
        @cmd.stub!(:open).and_return(@tempfile)
      end

      it "should open the artifact's location" do
        @cmd.should_receive(:artifact_location).with(@artifact).and_return('location')
        @cmd.should_receive(:open).with('location').and_return(@tempfile)
        @cmd.pull_artifact(@artifact)
      end

      it "should have filename from artifact's uri" do
        @uri.should_receive(:path).and_return('/path/to/artifact.war')
        @cmd.pull_artifact(@artifact)[:filename].should == 'artifact.war'
      end

      it "should have type from artifact's content_type" do
        @tempfile.should_receive(:content_type).and_return('content_type')
        @cmd.pull_artifact(@artifact)[:type].should == 'content_type'
      end

      it "should have tempfile from artifact's tempfile" do
        @cmd.pull_artifact(@artifact)[:tempfile].should == @tempfile
      end
    end

  end
end

