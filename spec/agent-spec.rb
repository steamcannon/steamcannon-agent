ENV['RACK_ENV'] = 'test'

require 'sinatra'
require 'thin/logging'
require 'sc-agent/agent'
require 'rack/test'

set :environment, :test
set :run, false
set :logging, false

module SteamCannon
  describe Agent do
    include Rack::Test::Methods

    def app
      @app ||= Agent
    end

    def parse_response( response )
      JSON.parse( response.body, :symbolize_names => true) if response.body.length > 0
    end

    it "should return the current version" do
      get '/api_version'

      response = parse_response( last_response )

      last_response.status.should == 200
      response[:api_version].should == SteamCannon::Agent::API_VERSION
    end
    
    it "should return current status" do
      exec_helper = mock( ExecHelper )
      exec_helper.should_receive(:execute).with('cat /proc/loadavg').and_return('0.04 0.05 0.00 1/91 1851')

      ExecHelper.should_receive(:new).and_return( exec_helper )

      get '/status'

      response = parse_response( last_response )

      last_response.status.should == 200
      response[:load].should == '0.04 0.05 0.00 1/91 1851'
    end

    it "should return error if something wents wrong" do
      ExecHelper.should_receive(:new).and_raise('something')

      get '/status'

      response = parse_response( last_response )

      last_response.status.should == 500
      response[:message].should == 'something'
    end

    it "should return the correct content-type" do
      get '/'

      last_response.headers["Content-Type"].should == "application/json;charset=utf-8"
    end

    describe 'cluster_member_addresses' do
      before(:each) do
        @helper = mock(ClusterMemberAddressHelper)
        ClusterMemberAddressHelper.should_receive(:new).and_return(@helper)
      end
      
      it "should create a cluster member address" do
        @helper.should_receive(:execute).with(:create, 'a_hostname', 'an_address')
        post '/cluster_member_addresses', :hostname => 'a_hostname', :address => 'an_address'
      end
      
      it "should delete a cluster member address" do
        @helper.should_receive(:execute).with(:delete, 'a_hostname')
        delete "/cluster_member_addresses/a_hostname"
      end
    end
    
    it "should return 404 because service doesn't exists" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( false )

      get '/services/test/operation'

      response = parse_response( last_response )

      last_response.status.should == 404
      response[:message].should == "Service 'test' doesn't exists."
    end

    it "should return 500 because operation is not allowed" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )
      ServiceManager.should_receive(:execute_operation).with('test', 'operation').and_raise( "Operation 'operation' is not supported in Test service" )

      get '/services/test/operation'

      response = parse_response( last_response )

      last_response.status.should == 500
      response[:message].should == "Operation 'operation' is not supported in Test service"
    end

    it "should execute stop operation on service" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )
      ServiceManager.should_receive(:execute_operation).with('test', 'stop')

      post '/services/test/stop'

      last_response.status.should == 200
    end

    it "should not execute abc operation on service" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )
      ServiceManager.should_not_receive(:execute_operation)

      post '/services/test/abc'

      response = parse_response( last_response )

      last_response.status.should == 500
      response[:message].should == "Operation 'abc' is not allowed. Allowed operations: start, stop, restart."
    end

    it "should get the artifact" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )
      ServiceManager.should_receive(:execute_operation).with('test', 'artifact', '1').and_return( { :artifact => 'artifact'} )

      get '/services/test/artifacts/1'

      response = parse_response( last_response )

      last_response.status.should == 200
      response[:artifact].should == 'artifact'
    end

    it "should get 404 because artifact doesn't exists anymore" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )
      ServiceManager.should_receive(:execute_operation).with('test', 'artifact', '1').and_raise( NotFound.new("No artifact") )

      get '/services/test/artifacts/1'

      response = parse_response( last_response )

      last_response.status.should == 404
      response[:message].should == 'No artifact'
    end

    it "should not deploy a new artifact because no artifact was specified" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )

      post '/services/test/artifacts'

      response = parse_response( last_response )

      last_response.status.should == 404
      response[:message].should == "No 'artifact' parameter specified in request"
    end

    it "should deploy a new artifact" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )
      ServiceManager.should_receive(:execute_operation).with('test', 'deploy', 'something').and_return( { :artifact_id => 1 } )

      post '/services/test/artifacts', :artifact => 'something'

      response = parse_response( last_response )

      last_response.status.should == 200
      response[:artifact_id].should == 1
    end

    it "should not configure the service because no config was specified" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )

      post '/services/test/configure'

      response = parse_response( last_response )

      last_response.status.should == 404
      response[:message].should == "No 'config' parameter specified in request"
    end

    it "should configure the service" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )
      ServiceManager.should_receive(:execute_operation).with('test', 'configure', 'something').and_return( { :state => :started } )

      post '/services/test/configure', :config => 'something'

      response = parse_response( last_response )

      last_response.status.should == 200
      response[:state].should == 'started'
    end

    it "should delete the artifact" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:service_exists?).with('test').and_return( true )
      ServiceManager.should_receive(:execute_operation).with('test', 'undeploy', '1').and_return( { :status => "ok" } )

      delete '/services/test/artifacts/1'

      last_response.status.should == 200
    end

    it "should configure and restart the service" do
      ServiceManager.should_receive(:configure).with( 'CERT', 'KEY' )

      post '/configure', :certificate => 'CERT', :keypair => 'KEY'

      last_response.status.should == 200
    end

    it "should try to access /services before configuring" do
      ServiceManager.should_receive(:is_configured).and_return( false )

      get '/services'

      last_response.status.should == 404
    end

    it "should try to access /services after configuring" do
      ServiceManager.should_receive(:is_configured).and_return( true )
      ServiceManager.should_receive(:services_info).and_return('something')

      get '/services'

      last_response.status.should == 200
    end

  end
end
