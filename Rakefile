require 'echoe'

Echoe.new("ct-agent") do |p|
  p.project     = "SteamCannon Agent"
  p.author      = "SteamCannon Team"
  p.summary     = "SteamCannon Agent responsible for managing various services such as JBoss AS"
  p.url         = "http://www.jboss.org/steamcannon"
  p.ignore_pattern  = /^(pkg|doc|ssl|spec)|\.svn|CVS|\.bzr|\.DS|\.git|\.log|\.gem/
  p.test_pattern = 'spec/**/*'
  p.spec_pattern = 'spec/**/*'
  p.runtime_dependencies = ["sinatra ~>1.0", "thin ~>1.2.8", "dm-core ~>1.0.0", "dm-sqlite-adapter ~>1.0.0", "dm-migrations ~>1.0.0", "dm-is-tree ~>1.0.0", "json ~>1.4.6", "open4 ~>1.0.1"]
  p.development_dependencies = ["rake", "echoe", "rspec", "rcov"]
end
