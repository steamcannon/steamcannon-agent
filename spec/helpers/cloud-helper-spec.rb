require 'sc-agent/helpers/cloud-helper'

module SteamCannon
  describe CloudHelper do
    before(:each) do
      @client_helper = mock( ClientHelper )

      @helper = CloudHelper.new( :log => Logger.new('/dev/null'), :client_helper => @client_helper )
    end

    it "should discover if we're on EC2" do
      @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/meta-data/local-ipv4').and_return('127.0.0.1')
      @helper.discover_ec2.should == true
    end

    it "should discover if we're on EC2 and return false if not" do
      @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/meta-data/local-ipv4').and_return(nil)
      @helper.discover_ec2.should == false
    end

    it "should discover platform" do
      @helper.should_receive(:discover_ec2).and_return(false)
      @helper.discover_platform.should == :unknown
    end

    describe ".read_certificate" do
      it "should read certificate for EC2" do
        @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/user-data').and_return('{ "steamcannon_certificate": "CERT" }')
        @helper.read_certificate( :ec2 ).should == "CERT"
      end

      it "should read certificate for EC2 and return nil because there is no certificate in UserData" do
        @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/user-data').and_return('{}')
        @helper.read_certificate( :ec2 ).should == nil
      end

      it "should read certificate for EC2 and return nil because UserData is not in JSON format" do
        @client_helper.should_receive(:get).with('http://169.254.169.254/1.0/user-data').and_return('{sdf}')
        @helper.read_certificate( :ec2 ).should == nil
      end
    end
  end
end
