require 'sc-agent/services/postgresql/commands/configure-command'

module SteamCannon
  describe PostgreSQL::ConfigureCommand do

    before(:each) do
      @service        = mock( 'Service' )
      @service_helper = mock( ServiceHelper )
      @db             = mock("DB")

      @service.stub!( :service_helper ).and_return( @service_helper )
      @service.stub!(:db).and_return( @db )
      @service.stub!( :config ).and_return({ })
      @service.stub!(:name).and_return( "postgresql" )

      @service.stub!(:state).and_return( :stopped )

      @db.stub!(:save_event)

      @log            = Logger.new('/dev/null')
      @cmd            = PostgreSQL::ConfigureCommand.new( @service, :log => @log )
      @cmd.stub!(:psql).and_return("psql stub called")
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
    end

    context 'it should not configure when' do
      before(:each) do
        @service.instance_variable_set(:@state, :stopped)

        db1 = mock("db1")
        db1.should_receive( :save_event ).with( :configure, :started ).and_return("1")
        @service.should_receive(:db).and_return( db1 )

        db2 = mock("db2")
        db2.should_receive( :save_event ).with( :configure, :failed, :msg => "No or invalid data provided to configure service." )
        @service.should_receive(:db).and_return( db2 )

      end

      it "it is passed nil data" do
        begin
          @cmd.execute( nil )
          raise "Should raise"
        rescue => e
          e.message.should == "No or invalid data provided to configure service."
        end
      end

    end


    describe 'configure' do

      it "should return an error when an error occurs" do
        @cmd.configure(:blah => 'ding').should == { :error => "An error occurred while configuring 'postgresql' service: Invalid command :blah given" }
      end

      context "when given the :create_admin command" do
        before(:each) do
          @payload = { :user => 'username', :password => 'userpassword' }
          @data = { :create_admin => @payload }
        end

        it "should delegate to create_admin" do
          @cmd.should_receive(:create_admin).with(@payload)
          @cmd.configure(@data)
        end

        it "should return the result from the command" do
          @cmd.stub!(:create_admin).and_return("the result")
          @cmd.configure(@data).should == 'the result'
        end
      end
    end

    describe "create_admin" do
      before(:each) do
        @payload = { :user => 'username', :password => 'userpassword' }
      end
      
      it "should delegate to psql" do
        @cmd.should_receive(:psql).with("CREATE ROLE username WITH PASSWORD 'userpassword' SUPERUSER")
        @cmd.send(:create_admin, @payload)
      end

      it "should escape any sql in the username/pw" do
        @cmd.should_receive(:escape_sql).with('username').and_return('username')
        @cmd.should_receive(:escape_sql).with('userpassword').and_return('userpassword')
        @cmd.send(:create_admin, @payload)
      end

      it "should return nil on success" do
        @cmd.send(:create_admin, @payload).should be_nil
      end
    end

    describe "escape_sql" do
      it "should sanitize sql"
    end
    
  end
end

