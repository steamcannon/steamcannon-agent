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

module SteamCannon
  class BaseService
    attr_accessor :state

    attr_reader :db
    attr_reader :name
    attr_reader :full_name
    attr_reader :service_helper
    attr_reader :config
    
    def initialize( options = {} )
      @db = ServiceManager.register( self, @full_name )
      
      @log            = options[:log]             || Logger.new(STDOUT)
      @exec_helper    = options[:exec_helper]     || ExecHelper.new( :log => @log )
      @config         = options[:config]
      @service_helper = ServiceHelper.new( self, :log => @log )
      
      # TODO should we also include :error status?
      @state                  = :stopped # available statuses: :starting, :started, :configuring, :stopping, :stopped
    end

    #TODO: move common actions here as well
  end
end
