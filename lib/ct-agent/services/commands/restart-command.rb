require 'ct-agent/helpers/exec-helper'
require 'logger'

class RestartCommand
  def initialize( service, options = {} )
    @service        = service
    @state          = @service.state

    @log            = options[:log]             || Logger.new(STDOUT)
    @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )
    @threaded       = options[:threaded]        || false
  end

  def execute( event = nil )
    @service.db.save_event( :restart, :started, :parent => event )

    unless [:stopped, :started].include?( @state )
      msg = "Current service status ('#{@state}') does not allow to restart the service."
      @log.error msg
      @service.db.save_event( :restart, :failed, :parent => event, :msg => msg )
      return { :status => 'error', :msg => msg }
    end

    @service.state = :restarting
    @log.debug "Current status is '#{@state}', restarting '#{@service.name}' service"

    if @threaded
      Thread.new{ restart( event ) }
    else
      restart( event )
    end

    { :status => 'ok', :response => { :state => @service.state } }
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
