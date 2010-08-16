require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'sinatra/base'
require 'ct-agent/helpers/log-helper'
require 'ct-agent/helpers/config-helper'
require 'ct-agent/managers/db-manager'
require 'ct-agent/managers/service-manager'
require 'rack'
require 'thin/controllers/controller'
require 'json'

module CoolingTower
  class Agent < Sinatra::Base
    config = ConfigHelper.new.config

    unless config.log_level.nil?
      log = LogHelper.new( :location => 'log/agent.log', :threshold => config.log_level.to_sym )
    else
      log = LogHelper.new( :location => 'log/agent.log', :threshold => :info )
    end

    log.trace config.to_yaml

    DBManager.new( :log => log ).prepare_db
    ServiceManager.prepare( config, log )

    set :raise_errors, true
    set :logging, false
    set :lock, false

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
        halt 415, {
                :status     => 'error',
                :message    => "No '#{name}' parameter specified in request"
        }.to_json if params[name.to_sym].nil?
      end
    end

    get '/status' do
      { :status => 'ok' }.to_json
    end

    get '/services' do
      { :status => 'ok', :response => ServiceManager.services_info }.to_json
    end

    ServiceManager.services_info.each do |service_info|
      # noargs
      [:status, :artifacts].each do |operation|
        get "/services/#{service_info[:name]}/#{operation}" do
          ServiceManager.execute_operation( service_info[:name], operation ).to_json
        end
      end

      [:start, :stop, :restart].each do |operation|
        post "/services/#{service_info[:name]}/#{operation}" do
          ServiceManager.execute_operation( service_info[:name], operation ).to_json
        end
      end

      # args
      post "/services/#{service_info[:name]}/artifacts" do
        validate_parameter( 'artifact' )
        ServiceManager.execute_operation( service_info[:name], 'deploy', params[:artifact] ).to_json
      end

      delete "/services/#{service_info[:name]}/artifacts/:id" do
        ServiceManager.execute_operation( service_info[:name], 'undeploy', params[:id] ).to_json
      end
    end
  end
end
