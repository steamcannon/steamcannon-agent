#
# Copyright 2010 Red Hat, Inc.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'sinatra/base'
require 'ct-agent/helpers/log-helper'
require 'ct-agent/helpers/config-helper'
require 'ct-agent/helpers/exec-helper'
require 'ct-agent/managers/db-manager'
require 'ct-agent/managers/service-manager'
require 'rack'
require 'thin/controllers/controller'
require 'json'

module CoolingTower
  class Agent < Sinatra::Base
    log = LogHelper.new( :location => 'log/agent.log' )

    log.info "Launching Agent..."

    config = ConfigHelper.new( :log => log ).config

    log.change_threshold( config.log_level.to_sym )

    log.trace config.to_yaml

    DBManager.new( :log => log ).prepare_db
    ServiceManager.prepare( config, log ).load_services

    set :raise_errors, false
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
      { :status => 'ok', :response => {:load => ExecHelper.new( :log => Logger.new('/dev/null') ).execute("cat /proc/loadavg") } }.to_json
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

      get "/services/#{service_info[:name]}/artifacts/:id" do
        ServiceManager.execute_operation( service_info[:name], 'artifact', params[:id] ).to_json
      end

      # args
      post "/services/#{service_info[:name]}/artifacts" do
        validate_parameter( 'artifact' )
        ServiceManager.execute_operation( service_info[:name], 'deploy', params[:artifact] ).to_json
      end

      post "/services/#{service_info[:name]}/configure" do
        validate_parameter( 'config' )
        ServiceManager.execute_operation( service_info[:name], 'configure', params[:config] ).to_json
      end

      delete "/services/#{service_info[:name]}/artifacts/:id" do
        ServiceManager.execute_operation( service_info[:name], 'undeploy', params[:id] ).to_json
      end
    end
  end
end
