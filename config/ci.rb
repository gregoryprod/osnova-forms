CI.run do
  step "Prepare", "bin/rails db:prepare"
  step "Rails tests", "bin/rails test"
  step "JavaScript tests", "node --test test/javascript/embed_test.cjs"
  step "Autoload", "bin/rails zeitwerk:check"
end
