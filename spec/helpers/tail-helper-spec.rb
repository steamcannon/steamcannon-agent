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

require 'sc-agent/helpers/tail-helper'

module SteamCannon
  describe TailHelper do
    before(:each) do
      @log_file = File.join(File.dirname(__FILE__), '..', 'fixtures', 'sample.log')
    end

    it "should tail with no offset" do
      helper = TailHelper.new(@log_file, nil)
      helper.tail('5').last.should == "log_level: trace\n"
    end

    it "should tail with offset" do
      helper = TailHelper.new(@log_file, 278)
      helper.tail(1).last.should == "ssl_cert_file_name: cert.pem\n"
    end

    it "should not error when tailing to end of file" do
      helper = TailHelper.new(@log_file, 0)
      lambda {
        helper.tail(10000).last.should == ">> Stopping ...\n"
      }.should_not raise_error
    end

    it "should not change offset when already at end of file" do
      helper = TailHelper.new(@log_file, 3540)
      helper.tail(10)
      helper.offset.should be(3540)
    end

    it "should accept a negative offset to read from the end" do
      helper = TailHelper.new(@log_file, -275)
      helper.tail(10).first.should == "I, [2010-09-21 17:00:31 #15949]  INFO -- : Discovering platform...\n"
      helper.offset.should be(3540)
    end

    it "should handle negative offsets larger than the file size" do
      helper = TailHelper.new(@log_file, -123456789)
      helper.tail(1).last.should == "I, [2010-09-08 17:50:19 #51349]  INFO -- : Initializing Agent...\n"
    end

    it "should handle offsets larger than the file size" do
      helper = TailHelper.new(@log_file, 123456789)
      helper.tail(1).last.should == nil
    end

  end
end
