require 'sc-agent/services/jboss_as/commands/update-proxy-list-command'

module SteamCannon
  describe UpdateProxyListCommand do

    before(:each) do
      Socket.should_receive(:gethostname).any_number_of_times.and_return("localhost")
    end

    describe "when stopped" do
      before(:each) do
        @cmd = UpdateProxyListCommand.new( :log => Logger.new('/dev/null'), :state => :stopped )
        @cmd.stub!(:write_proxy_config)
        @proxy_list = {"10.1.0.1" => {:host => "10.1.0.1", :port => 80}}
      end

      it "should write_proxy_config" do
        @cmd.should_receive(:write_proxy_config)
        @cmd.execute(@proxy_list)
      end

      it "should not update_running_jboss" do
        @cmd.should_not_receive(:update_running_jboss)
        @cmd.execute(@proxy_list)
      end
    end

    describe "when started" do
      before(:each) do
        @cmd = UpdateProxyListCommand.new( :log => Logger.new('/dev/null'), :state => :started )
        @cmd.stub!(:write_proxy_config)
        @cmd.stub!(:update_running_jboss)
        @proxy_list = {"10.1.0.1" => {:host => "10.1.0.1", :port => 80}}
      end

      it "should write_proxy_config" do
        @cmd.should_receive(:write_proxy_config)
        @cmd.execute(@proxy_list)
      end

      it "should update_running_jboss" do
        @cmd.should_receive(:update_running_jboss)
        @cmd.execute(@proxy_list)
      end
    end

    describe "write_proxy_config" do
      before(:each) do
        @cmd = UpdateProxyListCommand.new(:log => Logger.new('/dev/null'), :state => :started)
        @proxy_list = {"10.1.0.1" => {:host => "10.1.0.1", :port => 80}}
        @config_path = JBossASService::JBOSS_AS_SYSCONFIG_FILE
        File.stub!(:read).and_return("")
        @file = mock(File)
        @file.stub!(:write)
        File.stub!(:open).and_yield(@file)
      end

      it "should read the jboss_as config file" do
        File.should_receive(:read).with(@config_path).and_return("")
        @cmd.write_proxy_config(@proxy_list)
      end

      it "should write out the new config file" do
        @file.should_receive(:write)
        File.should_receive(:open).with(@config_path, 'w').and_yield(@file)
        @cmd.write_proxy_config(@proxy_list)
      end

      it "should have correct file contents" do
        @file.should_receive(:write).with("\nJBOSS_PROXY_LIST='10.1.0.1:80'")
        @cmd.write_proxy_config(@proxy_list)
      end
    end

    describe "update_running_jboss" do
      before(:each) do
        @cmd = UpdateProxyListCommand.new( :log => Logger.new('/dev/null'), :state => :started )
        @cmd.stub!(:write_proxy_config)
        @exec_helper = @cmd.instance_variable_get(:@exec_helper)
      end

      it "should do nothing if nil is submitted" do
        @cmd.execute( nil )
      end

      it "should add one proxy" do
        @cmd.stub!(:get_current_proxies).and_return({})

        @cmd.should_receive(:add_proxy).once.with( "10.1.0.1", 80 )
        @cmd.should_not_receive(:remove_proxy)

        @cmd.execute( { "10.1.0.1" => { :host => "10.1.0.1", :port => 80 } } )
      end

      it "should update one proxy" do
        @cmd.stub!(:get_current_proxies).and_return({ "10.1.0.1" => { :host => "10.1.0.1", :port => 1234 } })

        @cmd.should_receive(:remove_proxy).once.with( "10.1.0.1", 1234 )
        @cmd.should_receive(:add_proxy).once.with( "10.1.0.1", 80 )

        @cmd.execute( { "10.1.0.1" => { :host => "10.1.0.1", :port => 80 } } )
      end

      it "should remove one proxy" do
        @cmd.stub!(:get_current_proxies).and_return({ "10.1.0.1" => { :host => "10.1.0.1", :port => 1234 } })

        @cmd.should_receive(:remove_proxy).once.with( "10.1.0.1", 1234 )
        @cmd.should_not_receive(:add_proxy)
        @cmd.execute( {} )
      end

      it "should update proxy port" do
        @cmd.stub!(:get_current_proxies).and_return({ "10.1.0.1" => { :host => "10.1.0.1", :port => 1234 } })

        @cmd.should_receive(:remove_proxy).once.with( "10.1.0.1", 1234 )
        @cmd.should_receive(:add_proxy).once.with( "10.1.0.1", 80 )

        @cmd.execute( { "10.1.0.1" => { :host => "10.1.0.1", :port => 80 } } )
      end

      it "should make a big update on proxy list" do
        @cmd.stub!(:get_current_proxies).and_return( {
                                                       "10.1.0.1" => { :host => "10.1.0.1", :port => 1234 },
                                                       "10.1.0.4" => { :host => "10.1.0.3", :port => 80 }
                                                     })

        @cmd.should_receive(:remove_proxy).once.with( "10.1.0.1", 1234 )
        @cmd.should_receive(:remove_proxy).once.with( "10.1.0.4", 80 )

        @cmd.should_receive(:add_proxy).once.with( "10.1.0.1", 80 )
        @cmd.should_receive(:add_proxy).once.with( "10.1.0.2", 80 )
        @cmd.should_receive(:add_proxy).once.with( "10.1.0.3", 80 )

        @cmd.execute( { "10.1.0.1" => { :host => "10.1.0.1", :port => 80 }, "10.1.0.2" => { :host => "10.1.0.2", :port => 80 }, "10.1.0.3" => { :host => "10.1.0.3", :port => 80 } } )
      end

      it "should load 2 proxies" do
        @exec_helper.should_receive(:execute).with( "/opt/jboss-as/bin/twiddle.sh -o localhost -u admin -p admin get jboss.web:service=ModCluster ProxyInfo" ).once.and_return("ProxyInfo={/10.210.30.227:80=Node: [1],Name: localhost.localdomain-10.211.94.34,Balancer: mycluster,Domain: ,Host: 10.211.94.34,Port: 8009,Type: ajp,Flushpackets: Off,Flushwait: 10000,Ping: 10000000,Smax: 1,Ttl: 60000000,Elected: 0,Read: 0,Transfered: 0,Connected: 0,Load: 93 Node: [2],Name: localhost.localdomain-10.210.59.133,Balancer: mycluster,Domain: ,Host: 10.210.59.133,Port: 8009,Type: ajp,Flushpackets: Off,Flushwait: 10000,Ping: 10000000,Smax: 1,Ttl: 60000000,Elected: 0,Read: 0,Transfered: 0,Connected: 0,Load: 97 , /10.210.85.220:80=Node: [1],Name: localhost.localdomain-10.211.94.34,Balancer: mycluster,Domain: ,Host: 10.211.94.34,Port: 8009,Type: ajp,Flushpackets: Off,Flushwait: 10000,Ping: 10000000,Smax: 1,Ttl: 60000000,Elected: 0,Read: 0,Transfered: 0,Connected: 0,Load: 93 Node: [2],Name: localhost.localdomain-10.210.59.133,Balancer: mycluster,Domain: ,Host: 10.210.59.133,Port: 8009,Type: ajp,Flushpackets: Off,Flushwait: 10000,Ping: 10000000,Smax: 1,Ttl: 60000000,Elected: 0,Read: 0,Transfered: 0,Connected: 0,Load: 97}")
        @cmd.get_current_proxies.size.should == 2
      end

      it "should load 1 proxy" do
        @exec_helper.should_receive(:execute).with( "/opt/jboss-as/bin/twiddle.sh -o localhost -u admin -p admin get jboss.web:service=ModCluster ProxyInfo" ).once.and_return("ProxyInfo={/10.210.30.227:80=Node: [1],Name: localhost.localdomain-10.211.94.34,Balancer: mycluster,Domain: ,Host: 10.211.94.34,Port: 8009,Type: }")
        @cmd.get_current_proxies.size.should == 1
      end

      it "should execute twiddle_execute to add one proxy" do
        @cmd.should_receive(:twiddle_execute).with("invoke jboss.web:service=ModCluster addProxy 10.1.0.1 80")
        @cmd.add_proxy( "10.1.0.1", 80 )
      end

      it "should execute twiddle_execute to remove one proxy" do
        @cmd.should_receive(:twiddle_execute).with("invoke jboss.web:service=ModCluster removeProxy 10.1.0.1 80")
        @cmd.remove_proxy( "10.1.0.1", 80 )
      end

      it "should execute twiddle using exec_helper" do
        @exec_helper.should_receive(:execute).with("/opt/jboss-as/bin/twiddle.sh -o localhost -u admin -p admin invoke jboss.web:service=ModCluster removeProxy 10.1.0.1 80")
        @cmd.twiddle_execute( "invoke jboss.web:service=ModCluster removeProxy 10.1.0.1 80" )
      end
    end

  end
end

