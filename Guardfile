# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', :version => 2 do
  watch(/^spec\/(.*)_spec.rb/)
  watch(/^lib\/(.*)\.rb/)                              { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(/^spec\/spec_helper.rb/)                       { "spec" }
  
  # watch(/^lib\/zactor.rb/)                             { "spec/lib/actor_spec.rb" }
  
  watch(/^app\/(.*)\.rb/)                              { |m| "spec/app/#{m[1]}_spec.rb" }
end
