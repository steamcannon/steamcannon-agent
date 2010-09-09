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
require 'sinatra/base'
require 'sc-agent/helpers/bootstrap-helper'
require 'sc-agent/helpers/exec-helper'
require 'sc-agent/managers/service-manager'
require 'sc-agent/exceptions'
require 'thin/controllers/controller'
require 'json'

module SteamCannon
  class Agent < Sinatra::Base

    #set :dump_errors, false
    set :show_exceptions, false
    set :raise_errors, false
    set :logging, false
    set :lock, false
    set :run, false
    set :sessions, false

    error do
      exception = request.env['sinatra.error']
      status 404 if exception.is_a?( NotFound )
      { :status => 'error', :msg => exception.message }.to_json
    end

    after do
      content_type 'application/json', :charset => 'utf-8'
    end

    helpers do
      def execute_operation( service, operation, *params )
        raise NotFound, "Service '#{service}' doesn't exists." unless ServiceManager.service_exists?( service )

        yield if block_given?

        ServiceManager.execute_operation( service, operation, *params ).to_json
      end

      def validate_parameter( name )
        raise NotFound, "No '#{name}' parameter specified in request" if params[name].nil?
      end
    end

    get '/status' do
      load = ExecHelper.new( :log => '/dev/null' ).execute('cat /proc/loadavg').strip.chomp

      { :status => 'ok', :response => { :load => load } }.to_json
    end

    get '/services' do
      { :status => 'ok', :response => ServiceManager.services_info }.to_json
    end

    post '/configure' do
      validate_parameter( :certificate )
      validate_parameter( :keypair )
      validate_parameter( :ca )
      # reconfigure here
      { :status => 'ok', :response => '????'}.to_json
    end

    get '/services/:service/:operation'do
      execute_operation( params[:service], params[:operation] )
    end

    post "/services/:service/configure" do
      execute_operation( params[:service], 'configure', params[:config] ) do
        validate_parameter( :config )
      end
    end

    post "/services/:service/artifacts" do
      execute_operation( params[:service], 'deploy', params[:artifact] ) do
        validate_parameter( :artifact )
      end
    end

    post '/services/:service/:operation'do
      execute_operation( params[:service], params[:operation] ) do
        raise "Operation '#{params[:operation]}' is not allowed. Allowed operations: #{[:start, :stop, :restart].join(', ')}." unless [:start, :stop, :restart].include?( params[:operation].to_sym )
      end
    end

    get "/services/:service/artifacts/:id" do
      execute_operation( params[:service], 'artifact', params[:id] )
    end

    delete "/services/:service/artifacts/:id" do
      execute_operation( params[:service], 'undeploy', params[:id] )
    end
  end
end
