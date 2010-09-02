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

  def prepare_db
    DataMapper::Model.raise_on_save_failure = true
    DataMapper.setup(:default, 'sqlite::memory:')
    DataMapper.finalize
    DataMapper.auto_migrate!
  end
end