require 'ct-agent/helpers/exec-helper'
require 'logger'

class StartCommand
  def initialize( service, options = {} )
    @service        = service
    @state          = @service.state

    @log            = options[:log]             || Logger.new(STDOUT)
    @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )
    @threaded       = options[:threaded]        || false
  end

  def execute( event = nil )
    # service is already started!
    return { :status => 'ok', :response => { :state => :started} } if @state == :started

    @service.db.save_event( :start, :started, :parent => event )

    unless @state == :stopped
      msg = "Current service status ('#{@state}') does not allow to start the service."
      @log.error msg
      @service.db.save_event( :start, :failed, :parent => event, :msg => msg )
      return { :status => 'error', :msg => msg }
    end

    @service.state = :starting
    @log.debug "Current status is '#{@state}', starting '#{@service.name}' service"

    if @threaded
      Thread.new{ start( event ) }
    else
      start( event )
    end

    { :status => 'ok', :response => { :state => @service.state } }
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
end
