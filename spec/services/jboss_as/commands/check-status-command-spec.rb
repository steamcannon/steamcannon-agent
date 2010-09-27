require 'sc-agent/services/jboss_as/commands/check-status-command'

module SteamCannon
  describe CheckStatusCommand do

    before(:each) do
      @service = mock(Service)
      @service.stub!(:state).and_return(:starting)
      @service.stub!(:state=)
      
      @cmd = CheckStatusCommand.new(@service, :log => Logger.new('/dev/null'))
      @cmd.stub!(:jboss_as_running?).and_return(true)
    end

    it "should use twiddle to check JBoss AS status" do
      @cmd.should_receive(:jboss_as_running?).and_return(true)
      @cmd.execute
    end

    context 'when remote server is running' do
      it "should move the service from starting to started" do
        @service.stub!(:state).and_return(:starting)
        @service.should_receive(:state=).with(:started)
        @cmd.execute
      end

      it "should move the service from stopped to started" do
        @service.stub!(:state).and_return(:stopped)
        @service.should_receive(:state=).with(:started)
        @cmd.execute
      end

      [:started, :stopping, :configuring].each do |state|
        it "should not change state from :#{state}" do
          @service.stub!(:state).and_return(state)
          @service.should_not_receive(:state=)
          @cmd.execute
        end
      end
    end
    
    context 'when remote server is not running' do
      before(:each) do
        @cmd.stub!(:jboss_as_running?).and_return(false)
      end
      
      it "should move the service from started to stopped" do
        @service.stub!(:state).and_return(:started)
        @service.should_receive(:state=).with(:stopped)
        @cmd.execute
      end

      it "should move the service from stopping to stopped" do
        @service.stub!(:state).and_return(:stopping)
        @service.should_receive(:state=).with(:stopped)
        @cmd.execute
      end

      [:starting, :stopped, :configuring].each do |state|
        it "should not change state from :#{state}" do
          @service.stub!(:state).and_return(state)
          @service.should_not_receive(:state=)
          @cmd.execute
        end
      end
    end

    describe 'jboss_as_running?' do
      before(:each) do
        @cmd = CheckStatusCommand.new(nil, :log => Logger.new('/dev/null'))
      end

      it "should call the proper twiddle command" do
        @cmd.should_receive(:twiddle_execute).with('get jboss.system:type=Server Started').and_return('Started=true')
        @cmd.jboss_as_running?
      end

      it "should return true if the service is running" do
        @cmd.should_receive(:twiddle_execute).with('get jboss.system:type=Server Started').and_return('Started=true')
        @cmd.jboss_as_running?.should be_true
      end

      it "should return false if the service is not running" do
        @cmd.should_receive(:twiddle_execute).with('get jboss.system:type=Server Started').and_return('a failure or something')
        @cmd.jboss_as_running?.should_not be_true
      end

      it "should return false if the twiddle raises" do
        @cmd.should_receive(:twiddle_execute).with('get jboss.system:type=Server Started').and_raise(RuntimeError.new)
        @cmd.jboss_as_running?.should_not be_true
      end
    end

  end
end

