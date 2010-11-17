require 'sc-agent/services/jboss_as/commands/update-admin-credentials-command'

module SteamCannon
  describe UpdateAdminCredentialsCommand do

    before(:each) do
      @service = mock('service', :jboss_as_configuration => 'default')
      @cmd = UpdateAdminCredentialsCommand.new(:log => Logger.new('/dev/null'),
                                               :service => @service)
      @credentials = {:user => 'user', :password => 'password'}
    end

    context "execute" do
      it "should update jmx console credentials" do
        @cmd.should_receive(:update_jmx_console_credentials).with(@credentials)
        @cmd.execute(@credentials)
      end

      it "should return true update_jmx_console_credentials is true" do
        @cmd.should_receive(:update_jmx_console_credentials).and_return(true)
        @cmd.execute(@credentials).should be(true)
      end
    end

    context "update_jmx_console_credentials" do
      it "should update credentials with correct path" do
        @cmd.should_receive(:config_path).with("props/jmx-console-users.properties").and_return('path')
        @cmd.should_receive(:update_credentials).with('path', @credentials).and_return(true)
        @cmd.update_jmx_console_credentials(@credentials).should be(true)
      end
    end

    context "update_credentials" do
      before(:each) do
        File.stub!(:read).and_return('')
        @cmd.stub!(:write_credentials)
      end

      it "should read the existing file" do
        File.should_receive(:read).with('path').and_return('')
        @cmd.update_credentials('path', @credentials)
      end

      it "should write new credentials if password differs from existing" do
        File.should_receive(:read).with('path').and_return('user=not_password')
        @cmd.should_receive(:write_credentials).with('path', @credentials)
        @cmd.update_credentials('path', @credentials).should be(true)
      end

      it "should write new credentials if user differs from existing" do
        File.should_receive(:read).with('path').and_return('admin=admin')
        @cmd.should_receive(:write_credentials).with('path', @credentials)
        @cmd.update_credentials('path', @credentials).should be(true)
      end

      it "should not write new credentials if same as existing" do
        File.should_receive(:read).with('path').and_return("user=password")
        @cmd.should_not_receive(:write_credentials)
        @cmd.update_credentials('path', @credentials).should be(false)
      end
    end

    context "write_credentials" do
      it "should write credentials" do
        file = mock('file')
        File.should_receive(:open).with('path', 'w').and_yield(file)
        file.should_receive(:write).with("user=password")
        @cmd.write_credentials('path', @credentials)
      end
    end
  end
end
