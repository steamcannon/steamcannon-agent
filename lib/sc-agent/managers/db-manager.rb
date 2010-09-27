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

require 'fileutils'
require 'logger'
require 'dm-core'
require 'dm-migrations'
require 'sc-agent/models/service'
require 'sc-agent/models/event'
require 'sc-agent/models/artifact'

class DBManager
  def initialize( options = {} )
    @log  = options[:log] || Logger.new(STDOUT)

    DataMapper::Logger.new( @log, :debug )
  end

  def prepare_db(config)
    DataMapper::Model.raise_on_save_failure = true
    @log.debug "Creating db dir at #{config.db_dir}"
    FileUtils.mkdir_p(config.db_dir)
    db_url = "sqlite://#{config.db_dir}/#{config.db_file}"
    @log.info "Using db url: #{db_url}"
    DataMapper.setup(:default, db_url)
    DataMapper.finalize
    DataMapper.auto_migrate!
  end
end
