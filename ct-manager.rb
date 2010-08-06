$: << 'lib'

require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'managers/service-manager'
require 'managers/db-manager'
require 'yaml'

Dir["lib/services/*.rb"].each {|file| require file }

DBManager.new.prepare_db

set :static, false
set :environment, :development

error do
  'Error, sorry, something went wrong!'
end

not_found do
  '404, no idea where it is'
end

after do
  # TODO we should enable content-type negotiation 
  content_type 'application/x-yaml', :charset => 'utf-8'
end

helpers do
  def validate_service
    halt 415, response_builder( false, "Unrecognized service '#{params[:name]}'" ) if !params[:name].nil? and !ServiceManager.instance.service_exists?( params[:name] )
  end

  def validate_parameter( name )
    halt 415, response_builder( false, "No '#{name}' parameter specified in request" ) if params[name.to_sym].nil?
  end

  def execute_operation( service, operation, *args )
    ServiceManager.instance.execute_operation( service, operation, *args )
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
  { :operation => 'services', :status => 'ok', :response => ServiceManager.instance.services_info }.to_yaml
end

ServiceManager.instance.services_info.each do |service_info|
  # noargs
  [:status, :supported_operations, :artifacts].each do |operation|
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
