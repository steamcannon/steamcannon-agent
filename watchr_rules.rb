if __FILE__ == $0
  puts "Run with: watchr #{__FILE__}. \n\nRequired gems: watchr"
  exit 1
end

# --------------------------------------------------
# Convenience Methods
# --------------------------------------------------
def run(cmd)
  puts(cmd)
  system(cmd)
  puts '-' * 30
end

def run_all_specs
  run "spec -p '**/*-spec.rb' spec"
end

def run_single_spec *spec
  spec = spec.join(' ')
  run "spec #{spec}"
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------
#watch( '^spec/.*-spec\.rb' ) { |m| run_single_spec(m[0]) }
#watch( '^lib/sc-agent/(.*)\.rb' ) { |m| run_single_spec("spec/%s-spec.rb" % m[1]) }
# the specs have to be modified to require a good bit of stuff from
# lib/ to run individually, and they are fast enough to run all of
# them quickly, so let's do it!
watch( '^spec/.*-spec\.rb' ) { |m| run_all_specs }
watch( '^lib/sc-agent/.*\.rb' ) { |m| run_all_specs }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_specs
end
 
# Ctrl-C
Signal.trap('INT') { abort("\n") }

puts "Watching.."
