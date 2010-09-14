require 'sc-agent/helpers/ssl-helper'

module SteamCannon
  describe SSLHelper do
    before(:each) do

      options = OpenHash.new({ 'ssl_dir' => '/var', 'ssl_key_file_name' => 'ssl_key_file_name', 'ssl_cert_file_name' => 'ssl_cert_file_name', 'platform' => :ec2 })

      @helper = SSLHelper.new( options, :log => Logger.new('/dev/null') )

      @cloud_helper = @helper.instance_variable_get(:@cloud_helper)
    end

    it "should generate a certificate" do
      cert, rsa = @helper.create_self_signed_cert( 1024, [["C", "US"], ["O", "Red Hat"], ["CN", "localhost"]] )

      cert.is_a?(OpenSSL::X509::Certificate).should == true
      rsa.is_a?(OpenSSL::PKey::RSA).should == true
    end

    it "should generate self-signed cert and save it to a file" do
      cert = mock('Cert')
      key = mock('key')

      key.should_receive(:to_pem).and_return('key_pem')

      cert.should_receive(:to_text).and_return('cert_text')
      cert.should_receive(:to_pem).and_return('cert_pem')

      @helper.should_receive(:create_self_signed_cert).with(1024, [["C", "US"], ["ST", "NC"], ["O", "Red Hat"], ["CN", "localhost"]]).and_return([ cert, key ])

      File.should_receive(:open).with("/var/ssl_key_file_name", "w")
      File.should_receive(:open).with("/var/ssl_cert_file_name", "w")

      @helper.generate_self_signed_cert
    end

    it "should return ssl data when files already exists" do
      File.should_receive(:directory?).with( '/var' ).and_return(true)
      @cloud_helper.should_receive(:read_certificate).with(:ec2).and_return("CERT")

      File.should_receive(:exists?).with( '/var/ssl_key_file_name' ).and_return(true)
      File.should_receive(:exists?).with( '/var/ssl_cert_file_name' ).and_return(true)

      File.should_receive(:read).with( '/var/ssl_key_file_name' )
      File.should_receive(:read).with( '/var/ssl_cert_file_name' )

      @helper.ssl_data
    end

    it "should return ssl data and generate cert + key" do
      File.should_receive(:directory?).with( '/var' ).and_return(true)
      @cloud_helper.should_receive(:read_certificate).with(:ec2).and_return("CERT")

      File.should_receive(:exists?).with( '/var/ssl_key_file_name' ).and_return(false)

      @helper.should_receive(:generate_self_signed_cert)

      File.should_receive(:read).with( '/var/ssl_key_file_name' )
      File.should_receive(:read).with( '/var/ssl_cert_file_name' )

      @helper.ssl_data
    end

  end
end
