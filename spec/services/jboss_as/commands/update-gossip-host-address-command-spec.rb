require 'ct-agent/services/jboss_as/commands/update-gossip-host-address-command'

module CoolingTower
  describe UpdateGossipHostAddressCommand do

    before(:each) do
      @cmd            = UpdateGossipHostAddressCommand.new( :log => Logger.new('/dev/null') )
      @exec_helper    = @cmd.instance_variable_get(:@exec_helper)
      @string_helper  = @cmd.instance_variable_get(:@string_helper)
    end

    it "should raise if gossip host is not a string" do
      begin
        @cmd.execute( nil )
      rescue => e
        e.message.should == "Provided Gossip Host address is not valid, got NilClass, should be a String."
      end
    end

    it "should not update if gossip_host is the same" do
      File.should_receive(:read).with("/etc/sysconfig/jboss-as").and_return("JBOSS_GOSSIP_HOST=10.1.0.1")
      File.should_not_receive(:open)
      @cmd.execute( "10.1.0.1" ).should == false
    end

    it "should gossip_host update" do
      File.should_receive(:read).with("/etc/sysconfig/jboss-as").and_return("JBOSS_GOSSIP_HOST=10.1.0.1")

      f = mock(File)
      f.should_receive(:write ).with('JBOSS_GOSSIP_HOST=10.1.0.2')

      File.should_receive(:open).with("/etc/sysconfig/jboss-as", "w").and_yield(f)
      
      @cmd.execute( "10.1.0.2" ).should == true
    end

  end
end

