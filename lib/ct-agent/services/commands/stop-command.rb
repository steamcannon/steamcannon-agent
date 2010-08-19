require 'ct-agent/helpers/exec-helper'
require 'logger'

class StopCommand
  def initialize( service, options = {} )
    @service        = service
    @state          = @service.state

    @log            = options[:log]             || Logger.new(STDOUT)
    @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )
    @threaded       = options[:threaded]        || false
  end

  def execute( event = nil )
    # service is already started!
    return { :status => 'ok', :response => { :state => :stopped } } if @state == :stopped

    @service.db.save_event( :stop, :started, :parent => event )

    unless @state == :started
      msg = "Current service status ('#{@state}') does not allow to stop the service."
      @log.error msg
      @service.db.save_event( :stop, :failed, :parent => event, :msg =>msg )
      return { :status => 'error', :msg => msg }
    end

    @service.state = :stopping
    @log.debug "Current status is '#{@state}', stopping '#{@service.name}' service"

    if @threaded
      Thread.new{ stop( event ) }
    else
      stop( event )
    end

    { :status => 'ok', :response => { :state => @service.state } }
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
end
