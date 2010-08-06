$: << 'lib'

require 'rubygems'
require 'sinatra'
require 'managers/service-manager'
require 'yaml'

Dir["lib/services/*.rb"].each {|file| require file }

set :static, false
set :environment, :development

error do
  'Error, sorry, something went wrong!'
end

not_found do
  '404, no idea where it is'
end

after do
  content_type 'application/x-yaml', :charset => 'utf-8'
end

helpers do
  def validate_service
    halt 415, response_builder( false, "Unrecognized service '#{params[:name]}'" ) if !params[:name].nil? and !ServiceManager.instance.service_exists?( params[:name] )
  end

  def validate_parameter( name )
    halt 415, response_builder( false, "No '#{name}' parameter specified in request" ) if params[name.to_sym].nil?
  end

  def execute_operation( operation, *args )
    validate_service
    ServiceManager.instance.execute_operation( params[:name], operation, *args )
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
  {:operation => 'services', :status => 'ok', :response => ServiceManager.instance.services_info }.to_yaml
end

[:status, :supported_operations].each do |operation|
  get "/services/:name/#{operation}" do
    execute_operation( operation ).to_yaml
  end
end

get '/services/:name/artifacts' do
  execute_operation( 'artifacts' ).to_yaml
end

### POST

[:start, :stop, :restart].each do |operation|
  post "/services/:name/#{operation}" do
    execute_operation( operation ).to_yaml
  end
end

post '/services/:name/configure' do
  params[:operation] = 'configure'
  validate_parameter( 'file' )
  validate_parameter( 'path' )
  execute_operation( 'configure', params[:file], params[:path] ).to_yaml
end

post '/services/:name/artifacts/deploy' do
  validate_parameter( 'artifact' )
  execute_operation( 'deploy', params[:artifact] ).to_yaml
end

post '/services/:name/artifacts/undeploy' do
  validate_parameter( 'artifact_id' )
  execute_operation( 'undeploy', params[:artifact_id] ).to_yaml
end