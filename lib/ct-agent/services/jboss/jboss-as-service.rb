require 'ct-agent/services/base-service'
require 'ct-agent/services/jboss/commands/update-proxy-list-command'
require 'ct-agent/services/jboss/commands/update-gossip-host-address-command'

module CoolingTower
  class JBossASService < BaseService

    JBOSS_AS_SYSCONFIG_FILE = '/etc/sysconfig/jboss-as'

    def initialize
      register_service( :jboss_as, 'JBoss Application Server' )

      @jboss_config_file      = '/etc/sysconfig/jboss-as'
      @jboss_home             = '/opt/jboss-as'
      @default_configuration  = 'default'
      @service_name           = 'jboss-as6'

      @status                 = :stopped # available statuses: :starting, :started, :reconfiguring, :stopping, :stopped
    end

    def restart
      @db.save_event( :restart, :received )

      @status = :restarting

      Thread.new do
        manage_service( :restart )
      end

      @log.info "JBoss AS is restarting..."

      { :status => 'ok', :response => { :status => @status } }
    end

    def start
      @db.save_event( :start, :received )

      if @status == :started
        @db.save_event( :start, :finished )
        return { :status => 'ok', :response => { :status => @status } }
      end

      # if is NOT in stopped state
      unless @status == :stopped
        @db.save_event( :start, :failed )
        return { :status => 'error', :msg => "JBoss is currently in '#{@status}' state. It needs to be in 'stopped' state to execute this action." }
      end

      @log.info "Starting JBoss AS..."

      @status = :starting

      Thread.new do
        manage_service( :start )

        @status = :started
        @db.save_event( :start, :finished )
      end

      { :status => 'ok', :response => { :status => @status } }
    end

    def stop
      @db.save_event( :stop, :received )

      Thread.new do
        manage_service( :stop )
      end

      if [:stopped, :stopping].include?( @status )
        return { :status => 'ok', :response => { :status => @status, :call => :ignored } }
      end

      if [ :starting, :reconfiguring ].include?( @status )
        # delay the call?!
        # run in a thread, return current status?

        return { :status => 'ok', :response => { :status => @status, :call => :delayed } }
      end

      @log.info "JBoss AS is stopping..."

      @status = :stopping

      { :status => 'ok', :response => { :status => @status } }
    end

    def status
      { :status => 'ok', :response => { :status => @status } }
    end

    def configure( data )
      @db.save_event( :configure, :received )

      if @status == :reconfiguring
        @db.save_event( :configure, :failed )
        return { :status => 'error', :msg => "Previous reconfiguration still running, please be patient" }
      end

      invalid = true

      begin
        unless data.nil?
          data = JSON.parse( data )

          invalid = false if data.is_a?(Hash)
        end
      rescue
      end

      if invalid
        @db.save_event( :configure, :failed )
        return { :status => 'error', :msg => "No or invalid data specified to configure" }
      end

      status = @status
      @status = :reconfiguring

      @log.info "Reconfiguring JBoss AS..."

      Thread.new do
        begin
          restart = false

          restart = true if UpdateGossipHostAddressCommand.new( :log => @log ).execute( data['gossip_host'] ) unless data['gossip_host'].nil?
          restart = true if UpdateS3PingCredentialsCommand.new( :log => @log ).execute( data['s3_ping'] ) unless data['s3_ping'].nil?

          unless data['proxy_list'].nil?
            if status != :started

              unless manage_service( :start )
                @db.save_event( :configure, :failed )
                exit 1
              end
            end

            restart = true if UpdateProxyListCommand.new( @jboss_home, :log => @log ).execute( data['proxy_list'] ) unless data['proxy_list'].nil?
          end

          @status = status

          if restart
            unless manage_service( :restart )
              @db.save_event( :configure, :failed )
              exit 1
            end
          end

          @db.save_event( :configure, :finished )
        rescue => e
          @log.error e
          @log.error "An error occurred while updating JBoss configuration."
          @db.save_event( :configure, :failed )
          ##return { :status => 'error', :msg => "An error occurred while updating JBoss configuration. Some changes could be not saved." }
        end
      end

      { :status => 'ok', :response => { :status => @status} }
    end

    def artifacts

      artifacts = []

      @db.artifacts.each do |artifact|
        artifacts << { :name => artifact.name, :id => artifact.id }
      end

      { :status => 'ok', :response => artifacts }
    end

    def deploy( artifact )
      @db.save_event( :deploy, :received )

      #TODO base 64 decode artifact
      # validate the parameter, do the job, etc
      # Tempfile
      # FileUtils.cp( tempfile, "#{@jboss_home}/server/#{@default_configuration}/deploy/" )

      name = 'abc.war'

      if a = @db.save_artifact( :name => name, :location => "#{@jboss_home}/server/#{@default_configuration}/deploy/#{name}" )
        @db.save_event( :deploy, :finished )
        { :status => 'ok', :response => { :artifact_id => a.id } }
      else
        @db.save_event( :deploy, :failed )
        { :status => 'error', :msg => "Error while saving artifact" }
      end
    end

    def undeploy( artifact_id )
      @db.save_event( :undeploy, :received )

      # TODO: remove artifact from JBoss

      if @db.remove_artifact( artifact_id )
        @db.save_event( :undeploy, :finished )
        { :status => 'ok' }
      else
        @db.save_event( :undeploy, :failed )
        { :status => 'error', :msg => "Error occurred while removing artifact with id = '#{artifact_id}'" }
      end
    end

    protected

    def manage_service( operation )
      @log.info "Trying to #{operation} '#{@service_name}' service..."
      begin
        @db.save_event( operation, :received )
        @exec_helper.execute( "service #{@service_name} #{operation}" )
        @db.save_event( operation, :finished )
        @log.info "#{operation} operation executed on service #{@service_name}"
        true
      rescue
        @db.save_event( operation, :failed )
        false
      end
    end
  end
end