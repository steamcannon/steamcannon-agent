require 'sc-agent/services/jboss_as/commands/update-s3ping-credentials-command'

module SteamCannon
  describe UpdateS3PingCredentialsCommand do

    before(:each) do
      @cmd = UpdateS3PingCredentialsCommand.new( :log => Logger.new('/dev/null'))
    end

    it "should update credentials" do
      jboss_config_with_credentials = File.read("#{File.dirname(__FILE__)}/src/jboss-as6-credentials")

      File.should_receive(:open).once

      @cmd.instance_variable_set(:@jboss_config, jboss_config_with_credentials)
      @cmd.write_credentials( { :pre_signed_put_url => 'a', :pre_signed_delete_url => 'b' } )

      jboss_config = @cmd.instance_variable_get(:@jboss_config)

      jboss_config.scan(/^JBOSS_JGROUPS_S3_PING_PRE_SIGNED_PUT_URL=(.*)$/).to_s.should eql("a")
      jboss_config.scan(/^JBOSS_JGROUPS_S3_PING_PRE_SIGNED_DELETE_URL=(.*)$/).to_s.should eql("b")
    end

    it "should add credentials" do
      jboss_config_empty = File.read("#{File.dirname(__FILE__)}/src/jboss-as6-empty")

      File.should_receive(:open).once

      @cmd.instance_variable_set(:@jboss_config, jboss_config_empty)
      @cmd.write_credentials( { :pre_signed_put_url => 'a', :pre_signed_delete_url => 'b' } )

      jboss_config = @cmd.instance_variable_get(:@jboss_config)

      jboss_config.scan(/^JBOSS_JGROUPS_S3_PING_PRE_SIGNED_PUT_URL=(.*)$/).to_s.should eql("a")
      jboss_config.scan(/^JBOSS_JGROUPS_S3_PING_PRE_SIGNED_DELETE_URL=(.*)$/).to_s.should eql("b")
    end

    it "should read credentials" do
      jboss_config_mixed = File.read("#{File.dirname(__FILE__)}/src/jboss-as6-mixed")

      @cmd.instance_variable_set(:@jboss_config, jboss_config_mixed)
      credentials = @cmd.read_credentials

      credentials[:pre_signed_put_url].should eql("pre_signed_put_url")
      credentials[:pre_signed_delete_url].should eql("pre_signed_delete_url")
    end

    it "should raise if provided AWS credentials is not a hash" do
      begin
        @cmd.execute( nil )
      rescue => e
        e.message.should == "Credentials are in invalid format, got NilClass, should be a Hash."
      end
    end

    it "should update S3 credentials" do
      File.should_receive(:read).with("/etc/sysconfig/jboss-as").and_return("")
      @cmd.should_receive(:read_credentials).and_return({})
      @cmd.should_receive(:write_credentials).with({ :pre_signed_put_url => 'a', :pre_signed_delete_url => 'b' })

      @cmd.execute(  { :pre_signed_put_url => 'a', :pre_signed_delete_url => 'b' }  ).should == true
    end

    it "should not update S3 credentials" do
      File.should_receive(:read).with("/etc/sysconfig/jboss-as").and_return("")
      @cmd.should_receive(:read_credentials).and_return({ :pre_signed_put_url => 'a', :pre_signed_delete_url => 'b' })
      @cmd.should_not_receive(:write_credentials)

      @cmd.execute( { :pre_signed_put_url => 'a', :pre_signed_delete_url => 'b' } ).should == false
    end


  end
end

