$: << 'lib'

require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-migrations'
require 'managers/service-manager'
require 'managers/db-manager'
require 'yaml'
require 'json'
require "thin"
require "rack/content_length"
require "rack/chunked"

Dir["lib/services/*.rb"].each {|file| require file }

DBManager.new.prepare_db

class Thin128
  def self.run(app, options={})
    app = Rack::Chunked.new(Rack::ContentLength.new(app))

    server = ::Thin::Server.new(options[:Host] || '0.0.0.0',
                                options[:Port] || 8080,
                                app)

    server.ssl = true
    server.ssl_options = { :private_key_file => "ssl/private.key", :cert_chain_file =>  "ssl/cert.pem", :verify_peer => true }

    yield server if block_given?
    server.start
  end
end

Rack::Handler.register( 'thin128', 'Thin128' )

class CTManager < Sinatra::Base

  set :server, 'thin128'
  set :logging, true
  set :static, false
  set :environment, :development

  error do
    { :status => 'error', :msg => 'Error, sorry, something went wrong!' }.to_json
  end

  not_found do
    { :status => 'error', :msg => '404, no idea where it is' }.to_json
  end

  after do
    content_type 'application/json', :charset => 'utf-8'
  end

  helpers do
    def validate_parameter( name )
      halt 415, response_builder( false, "No '#{name}' parameter specified in request" ) if params[name.to_sym].nil?
    end

    def response_builder( success, message )
      {
              :operation  => params[:operation],
              :status     => (success ? 'ok' : 'error'),
              :message    => message
      }.to_yaml
    end
  end

  ServiceManager.instance.load_services

### GET

  get '/services' do
    { :status => 'ok', :response => ServiceManager.instance.services_info }.to_yaml
  end

  ServiceManager.instance.services_info.each do |service_info|
    # noargs
    [:status, :artifacts].each do |operation|
      get "/services/#{service_info[:name]}/#{operation}" do
        ServiceManager.instance.execute_operation( service_info[:name], operation ).to_yaml
      end
    end

    [:start, :stop, :restart].each do |operation|
      post "/services/#{service_info[:name]}/#{operation}" do
        ServiceManager.instance.execute_operation( service_info[:name], operation ).to_yaml
      end
    end

    # args
    post "/services/#{service_info[:name]}/artifacts" do
      validate_parameter( 'artifact' )
      ServiceManager.instance.execute_operation( service_info[:name], 'deploy', params[:artifact] ).to_yaml
    end

    delete "/services/#{service_info[:name]}/artifacts/:id" do
      ServiceManager.instance.execute_operation( service_info[:name], 'undeploy', params[:id] ).to_yaml
    end
  end
end

CTManager.run!