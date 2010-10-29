require 'sc-agent/services/jboss_as/commands/deploy-command'

module SteamCannon
  describe JBossAS::DeployCommand do

    before(:each) do
      @service        = mock( 'Service' )
      @service_helper = mock( ServiceHelper )

      @db = mock("DB")
      @db.stub!(:save_event)

      @service.stub!( :service_helper ).and_return( @service_helper )
      @service.stub!(:db).and_return( @db )

      @service.should_receive(:state).and_return( :stopped )

      @log            = Logger.new('/dev/null')
      @cmd            = JBossAS::DeployCommand.new( @service, :log => @log )
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

      file = mock("File")

      file.should_receive(:path).and_return('/tmp/file')
      @cmd.should_receive('`').with(/^cp/)
      @cmd.should_receive('`').with(/^chmod/)
      FileUtils.should_receive(:mv)
      FileUtils.should_receive(:mkdir_p).with("/opt/jboss-as/tmp")

      @db.should_receive( :save_event ).with( :deploy, :finished, :parent=>"1" )

      @cmd.execute( { :filename => "name.war", :tempfile => file, :type => "application/json" } ).should == { :status => :deployed }
    end

    context "when the artifact is a pull" do
      before(:each) do
        @cmd.stub!(:is_artifact_pull_url?).and_return(true)
        @artifact = mock('artifact')
      end

      it "should handle the deploy in a thread" do
        Thread.should_receive(:new)
        @cmd.execute(@artifact)
      end

      it "should return a pending status" do
        Thread.stub!(:new)
        @cmd.execute(@artifact).should == { :status => :pending }
      end

      it "should pull and write the artifact" do
        @cmd.should_receive(:pull_artifact)
        @cmd.should_receive(:write_and_move_artifact)
        @cmd.execute(@artifact).should == { :status => :pending }
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
        @tempfile = mock('tempfile')
        @tempfile.stub!(:path).and_return('/tmp/path')
        Tempfile.stub!(:new).and_return(@tempfile)
        @artifact = mock('artifact')
        @cmd.stub!(:artifact_location).and_return('http://location/to/artifact.war?asdf')
      end

      it "should shell out to curl" do
        @cmd.should_receive('`').with(/^curl .+/)
        @cmd.pull_artifact(@artifact)
      end

      it "should have filename from artifact's location" do
        @cmd.should_receive(:artifact_location).and_return('http://location/to/artifact.war?asdf')
        @cmd.pull_artifact(@artifact)[:filename].should == 'artifact.war'
      end

      it "should have tempfile from artifact's tempfile" do
        @cmd.pull_artifact(@artifact)[:tempfile].should == @tempfile
      end
    end

  end
end

