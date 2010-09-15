require 'sc-agent/helpers/ssl-helper'

module SteamCannon
  describe SSLHelper do
    CERT = "-----BEGIN CERTIFICATE-----
MIICKTCCAZKgAwIBAgIBATANBgkqhkiG9w0BAQUFADAsMR0wGwYDVQQKDBRTdGVh
bUNhbm5vbiBJbnN0YW5jZTELMAkGA1UEAwwCQ0EwHhcNMTAwOTE0MTcwMzU4WhcN
MjAwOTExMTcwMzU4WjAwMR0wGwYDVQQKDBRTdGVhbUNhbm5vbiBJbnN0YW5jZTEP
MA0GA1UEAwwGQ2xpZW50MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCYqK3k
TPczvpuR7s2UO0g4wky7sLiYh6g/x34XbHlD1pV8kv/ozAxT3F2xwfSbvQ+E1d5D
epK/1bENumyH7+VW5rbTZ2MMJPAfcy9aaFyWkSCoOVpK9a6dztrXlnhfo6li1jN2
PCv2my8vlukr6bGw7AhGf/+6RzZ4abQgbY7scQIDAQABo1cwVTAPBgNVHRMBAf8E
BTADAQEAMA4GA1UdDwEB/wQEAwIF4DATBgNVHSUEDDAKBggrBgEFBQcDAjAdBgNV
HQ4EFgQU/EhN8j+UpKlCKWSH6CtDhdeFLHYwDQYJKoZIhvcNAQEFBQADgYEAEMV+
CGjD3+jzmTYNIHzrBe6obKydBu1YWRkM3j2V3TOat9VXn2sJHA5IAfHJEueFSPjk
K/tY1fjVeM9tqei8pll9Yhv4itDc0DJb3W8giUUiY9KAaaNK9/oW5YpxbIkHyQZv
zwPRO10aTa/17290D2pegEuJ1T/vJm6rwdCw2cg=
-----END CERTIFICATE-----"

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
      @cloud_helper.should_receive(:read_certificate).with(:ec2).and_return(CERT)

      File.should_receive(:exists?).with( '/var/ssl_key_file_name' ).and_return(true)
      File.should_receive(:exists?).with( '/var/ssl_cert_file_name' ).and_return(true)

      File.should_receive(:read).with( '/var/ssl_key_file_name' )
      File.should_receive(:read).with( '/var/ssl_cert_file_name' )

      @helper.ssl_data
    end

    it "should return ssl data and generate cert + key" do
      File.should_receive(:directory?).with( '/var' ).and_return(true)
      @cloud_helper.should_receive(:read_certificate).with(:ec2).and_return(CERT)

      File.should_receive(:exists?).with( '/var/ssl_key_file_name' ).and_return(false)

      @helper.should_receive(:generate_self_signed_cert)

      File.should_receive(:read).with( '/var/ssl_key_file_name' )
      File.should_receive(:read).with( '/var/ssl_cert_file_name' )

      @helper.ssl_data
    end

  end
end
