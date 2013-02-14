require 'yard'
# Add "yard" task
YARD::Rake::YardocTask.new

task 'yard:server' do
  server = YARD::CLI::Server.new
  server.run(%w(-r))
end
