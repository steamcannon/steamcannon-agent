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

require 'sc-agent/helpers/exec-helper'
require 'logger'

class ServiceHelper
  def initialize( service, options = {} )
    @service        = service
    @state          = @service.state

    @log            = options[:log]             || Logger.new(STDOUT)
    @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )

    @actions        = {
            :start    => { :required => [:stopped], :transition => :starting, :target => :started },
            :stop     => { :required => [:started], :transition => :stopping, :target => :stopped },
            :restart  => { :required => [:started, :stopped], :transition => :restarting }
    }
  end

  def execute( action, options = {} )
    threaded = options[:backgroud] || false
    event    = options[:event]

    raise "Invalid action: #{action}" unless @actions.include?(action)

    return status if action != :restart and @state == @actions[action][:target]

    unless @actions[action][:required].include?(@state)
      msg = "Current service status ('#{@state}') does not allow to #{action} the service."
      @log.error msg
      raise msg
    end

    @service.db.save_event( action, :started, :parent => event )
    @service.state = @actions[action][:transition]
    @log.debug "Current service status is '#{@state}', #{@actions[action][:transition]} '#{@service.name}' service"

    if threaded
      Thread.new{ send( action, event ) }
    else
      send( action, event )
    end

    status
  end

  def status
    { :state => @service.state }
  end

  def start( event )
    begin
      @exec_helper.execute( "service #{@service.name} start" )
      @service.state = :started
      @service.db.save_event( :start, :finished, :parent => event )
      return true
    rescue
      # TODO do we need to ensure this is the right status?
      # back to old status
      msg = "An error occurred while starting '#{@service.name}' service"
      @log.error msg
      @service.state = @state
      @service.db.save_event( :start, :failed, :parent => event, :msg => msg )
      return false
    end
  end

  def stop( event )
    begin
      @exec_helper.execute( "service #{@service.name} stop" )
      @service.state = :stopped
      @service.db.save_event( :stop, :finished, :parent => event )
      return true
    rescue
      # TODO do we need to ensure this is the right status?
      # back to old status
      msg = "An error occurred while stopping '#{@service.name}' service"
      @log.error msg
      @service.state = @state
      @service.db.save_event( :stop, :failed, :parent => event, :msg => msg )
      return false
    end
  end

  def restart( event )
    begin
      @exec_helper.execute( "service #{@service.name} restart" )
      @service.state = :started
      @service.db.save_event( :restart, :finished, :parent => event )
      return true
    rescue
      # TODO do we need to ensure this is the right status?
      # back to old status
      msg = "An error occurred while restarting '#{@service.name}' service"
      @log.error msg
      @service.state = @state
      @service.db.save_event( :restart, :failed, :parent => event, :msg => msg )
      return false
    end
  end
end
