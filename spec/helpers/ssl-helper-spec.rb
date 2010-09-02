require 'sc-agent/helpers/ssl-helper'

module SteamCannon
  describe SSLHelper do
    before(:each) do
      @helper = SSLHelper.new( :log => Logger.new('/dev/null') )
    end

    it "should generate a certificate" do
      cert, rsa = @helper.create_self_signed_cert( 1024, [["C", "US"], ["O", "Red Hat"], ["CN", "localhost"]] )

      cert.is_a?(OpenSSL::X509::Certificate).should == true
      rsa.is_a?(OpenSSL::PKey::RSA).should == true
    end
  end
end
