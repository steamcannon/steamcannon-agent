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

require 'sc-agent/services/jboss_as/jboss-as-service'
require 'logger'

module SteamCannon
  describe JBossAS::TailCommand do
    before(:each) do
      @service = mock('Service')
      @log     = Logger.new('/dev/null')
      @cmd     = JBossAS::TailCommand.new(@service, :log => @log)
    end

    describe "execute" do
      before(:each) do
        @tail_helper = mock('TailHelper')
        TailHelper.stub!(:new).and_return(@tail_helper)
        @tail_helper.stub!(:tail).and_return([])
        @tail_helper.stub!(:offset).and_return(0)
        @cmd.stub!(:log_path).and_return('')
      end

      it "should generate a new TailHelper" do
        @cmd.should_receive(:log_path).with('log').and_return('log_path')
        TailHelper.should_receive(:new).with('log_path', 100)
        @cmd.execute('log', 20, 100)
      end

      it "should return num_lines from the helper" do
        @tail_helper.should_receive(:tail).and_return(['line'])
        @cmd.execute('log', 20, 100)[:lines].should == ['line']
      end

      it "should return offset from the helper" do
        @tail_helper.should_receive(:offset).and_return(120)
        @cmd.execute('log', 20, 100)[:offset].should be(120)
      end
    end

    describe "logs" do
      it "should glob for *.log" do
        @cmd.should_receive(:log_dir).and_return('/log_dir')
        Dir.should_receive(:glob).with("/log_dir/*.log").and_return(['test.log'])
        @cmd.logs.should == ['test.log']
      end
    end

    describe "log_dir" do
      it "should generate the correct dir" do
        @service.should_receive(:jboss_as_configuration).and_return('test-cluster')
        @cmd.log_dir.should == "#{JBossASService::JBOSS_AS_HOME}/server/test-cluster/log"
      end
    end

    describe "log_path" do
      it "should generate the correct path" do
        @cmd.should_receive(:log_dir).and_return('/log_dir')
        @cmd.log_path('asdf').should == "/log_dir/asdf"
      end
    end
  end
end
