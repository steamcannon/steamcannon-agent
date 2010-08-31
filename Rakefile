require 'echoe'

Echoe.new("ct-agent") do |p|
  p.project     = "CoolingTower Agent"
  p.author      = "Marek Goldmann"
  p.summary     = "Cooling Tower Agent responsible for managing various services such as JBoss AS"
  p.url         = "http://www.jboss.org/stormgrind/projects/coolingtower"
  p.ignore_pattern = /^(pkg|doc|ssl)|\.svn|CVS|\.bzr|\.DS|\.git|\.log|\.gem/
  p.runtime_dependencies = ["sinatra ~>1.0", "thin ~>1.2.8", "dm-core ~>1.0.0", "dm-sqlite-adapter ~>1.0.0", "dm-migrations ~>1.0.0", "dm-is-tree ~>1.0.0", "json ~>1.4.6", "open4 ~>1.0.1"]
end
