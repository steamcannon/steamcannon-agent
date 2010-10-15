require 'sc-agent/helpers/cluster-member-address-helper'
require 'ftools'

module SteamCannon
  describe ClusterMemberAddressHelper do
    TEST_HOSTS_FILE = '/tmp/cluster_member_address_helper_spec_hosts'
    FIXTURES_DIR = File.dirname(__FILE__) + "/../fixtures/host_files/"

    before(:each) do
      @helper = ClusterMemberAddressHelper.new(:log => Logger.new('/dev/null'))
      FileUtils.touch TEST_HOSTS_FILE
      @entry = %w{ a_host an_unresolved_address }
    end

    after(:each) do
      FileUtils.rm_f(TEST_HOSTS_FILE)
    end

    
    describe 'create' do
      context 'with valid address resolution' do
        before(:each) do
          Resolv.should_receive(:getaddress).with(@entry.last).and_return('an_address')
        end
        
        it "should add the entry to the file" do
          @helper.create(*@entry)
          File.compare(TEST_HOSTS_FILE, fixture(:hosts1)).should be_true
        end

        it "should first remove an entry for the host if it exists" do
          start_with_fixture(:hosts1)
          @helper.create(*@entry)
          File.compare(TEST_HOSTS_FILE, fixture(:hosts1)).should be_true
        end
      end

      it "should not make any changes if the address does not resolve" do
        Resolv.should_receive(:getaddress).and_raise(Resolv::ResolvError.new)
        start_with_fixture(:hosts2)
        @helper.create('another_host', 'a_bad_address')
        File.compare(TEST_HOSTS_FILE, fixture(:hosts2)).should be_true
      end
    end

    describe 'delete' do
      it "should remove a host entry from the file" do
        start_with_fixture(:hosts2)
        @helper.delete('another_host')
        host_file.read.should_not match /another_host/
      end
    end
    
    def fixture(name)
      FIXTURES_DIR + name.to_s
    end

    def start_with_fixture(name)
      FileUtils.cp(fixture(name), TEST_HOSTS_FILE)
    end
    
    def host_file
      File.new(TEST_HOSTS_FILE)
    end

    class ClusterMemberAddressHelper
      def hosts_file(mode = 'r', &block)
        File.open(TEST_HOSTS_FILE, mode, &block)
      end
    end
  end
end
