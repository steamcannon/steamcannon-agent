require 'sc-agent/services/postgresql/commands/initialize-command'

module SteamCannon
  describe PostgreSQL::InitializeCommand do

    before(:each) do
      @service        = mock( 'Service' )
      @service_helper = mock( ServiceHelper )
      @db             = mock("DB")
      @config         = OpenHash.new

      @db.stub!(:save_event)
      
      @service.stub!( :service_helper ).and_return( @service_helper )
      @service.stub!( :config ).and_return(@config)
      @service.stub!(:db).and_return( @db )
      @service.stub!(:name).and_return( "postgresql" )
      @service.stub!(:state).and_return( :stopped )
      @service.stub!(:start)
      
      @log            = Logger.new('/dev/null')
      @cmd            = PostgreSQL::InitializeCommand.new( @service, :log => @log )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
      @exec_helper.stub!(:execute)

    end

    describe 'initialize_db' do
      it "should write out the postgresql config" do
        @cmd.should_receive(:create_postgresql_sysconfig)
        @cmd.initialize_db
      end
      
      it "should update the config access permissions" do
        @cmd.should_receive(:update_host_access_permissions)
        @cmd.initialize_db
      end
      
      it "should init the db" do
        @cmd.should_receive(:initialize_database_config)
        @cmd.initialize_db
      end
      
      it "should chkconfig the service" do
        @cmd.should_receive(:register_service)
        @cmd.initialize_db
      end

      it "should start the service" do
        @service.should_receive(:start)
        @cmd.initialize_db
      end

      context 'when the db config already exists' do
        before(:each) do
          File.should_receive(:exists?).with(PostgreSQL::InitializeCommand::PSQL_ACCESS_FILE).and_return(true)
        end

        it "should not try to init the config" do
          @cmd.should_not_receive(:initialize_database_config)
          @cmd.initialize_db
        end

        it "should not try to update host perms" do
          @cmd.should_not_receive(:update_host_access_permissions)
          @cmd.initialize_db
        end
      end
      
      context "under ec2" do
        before(:each) do
          @config.platform = :ec2
        end
        
        it "should configure the ebs volume" do
          @cmd.should_receive(:initialize_ebs_volume)
          @cmd.initialize_db
        end
      end
    end

    describe('initialize_ebs_volume') do
      before(:each) do
        File.stub!(:exists?).and_return(true)
      end
      
      it "should look for the device" do
        File.should_receive(:exists?).with(PostgreSQL::InitializeCommand::STORAGE_VOLUME_DEVICE).and_return(true)
        @cmd.send(:initialize_ebs_volume)
      end

      it "should not format if the volume is formatted already" do
        @cmd.should_receive(:mount_ebs_volume).and_return("")
        @cmd.should_not_receive(:format_ebs_volume)
        @cmd.send(:initialize_ebs_volume)
      end

      it "should spin and wait for the device" do
        File.should_receive(:exists?).twice.with(PostgreSQL::InitializeCommand::STORAGE_VOLUME_DEVICE).and_return(false, true)
        @cmd.should_receive(:sleep).with(PostgreSQL::InitializeCommand::STORAGE_VOLUME_SLEEP_SECONDS)
        @cmd.send(:initialize_ebs_volume)
      end
      
      context 'when the volume is not formatted' do
        before(:each) do
          @cmd.should_receive(:mount_ebs_volume).once.and_raise(ExecHelper::ExecError.new('', "mount: you must specify the filesystem type"))
          @cmd.should_receive(:mount_ebs_volume).once.and_return("")
        end

        it "should format the device" do
          @cmd.should_receive(:format_ebs_volume)
          @cmd.send(:initialize_ebs_volume)
        end

        it "should mount the device" do
          @cmd.send(:initialize_ebs_volume)
        end
      end

      context 'when the volume is already mounted' do
        before(:each) do
          @cmd.should_receive(:mount_ebs_volume).once.and_raise(ExecHelper::ExecError.new('', "mount: /dev/xvdf already mounted or /data busy"))
        end
        
        it "should not raise" do
          lambda { @cmd.send(:initialize_ebs_volume) }.should_not raise_error
        end

        it "should not attempt to format the volume" do
          @cmd.should_not_receive(:format_ebs_volume)
          @cmd.send(:initialize_ebs_volume)
        end
      end
    end
  end
end

