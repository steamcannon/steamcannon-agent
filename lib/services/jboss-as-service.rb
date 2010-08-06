require 'services/base-service'

class JBossASService < BaseService
  def initialize
    register_service( :jboss_as, 'JBoss Application Server' )
  end

  def restart
    { :status => 'ok' }
  end

  def start
    @log.info "Starting JBoss AS..."

    # actual code

    @log.info "JBoss is starting..."

    { :status => 'ok', :response => { :jboss_status => :starting } }
  end

  def stop
    { :status => 'ok', :response => { :jboss_status => :stopping } }
  end

  def status
    # started, stopped, starting, stopping
    { :status => 'ok', :response => { :jboss_status => :started } }
  end

  def artifacts

    artifacts = []

    Artifact.all.each do |artifact|
      artifacts << { :name => artifact.name, :id => artifact.id }
    end

    { :status => 'ok', :response => artifacts }
  end

  def deploy( artifact )
    # validate the parameter, do the job, etc

    artifact = Artifact.create( :name => 'abc.war', :location => '/opt/test/abc.war', :service => @service )

    { :status => 'ok', :response => { :artifact_id => artifact.id } }
  end

  def undeploy( artifact_id )
    # validate the parameter, do the job, etc

    artifact = Artifact.get( artifact_id )

    if artifact.nil?
      { :status => 'error', :msg => "Artifact with id = '#{artifact_id}' not found" }
    else
      begin
        artifact.destroy
        { :status => 'ok' }
      rescue
        { :status => 'error', :msg => "Error occured while removing artifact with id = '#{artifact_id}'" }
      end
    end
  end
end