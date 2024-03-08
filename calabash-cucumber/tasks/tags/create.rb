# frozen_string_literal: true

namespace :tags do
  desc 'create a new tag locally and remotely'
  task :create do
    # check that the current branch is master
    puts "checking that current branch is 'master'"
    current_branch = `git branch --show-current`
    if !Process.last_status.success? || current_branch != "master\n"
      raise "this rake can only be run from 'master' branch\n"
    end

    # fetch latest origin state
    puts 'fetching remote branch & tags'
    `git fetch origin --tags`
    raise "this rake can only be run with an 'origin' remote setup\n" unless Process.last_status.success?

    # check that there are no differences between master and remote master
    puts 'checking diffs between local and remote master'
    differences = `git diff --name-only master origin/master`
    raise "please pull the latest changes to 'master' branch\n" if !Process.last_status.success? || differences != ''

    # check that there are no remote tags with same number
    current_version = Calabash::Cucumber::VERSION
    current_version_name = "v#{current_version}"
    puts "checking that no tag '#{current_version_name}' exists"
    tags_string = `git tag`
    tags_array = tags_string.split "\n"
    if tags_array.include? current_version_name
      raise "the tag '#{current_version_name}' already exists in the 'origin' remote, please bump the version further\n"
    end

    # create a local tag
    puts "creating local tag '#{current_version_name}'"
    `git tag -a #{current_version_name} -m "Version #{current_version}"`
    raise "failed to create the tag '#{current_version_name}' locally\n" unless Process.last_status.success?

    # push the tag to remote (or rollback)
    puts "pushing the tag '#{current_version_name}' to remote"
    `git push origin #{current_version_name}`
    unless Process.last_status.success?
      puts "deleting the local tag '#{current_version_name}' because pushing failed"
      `git tag -d #{current_version_name}`

      raise "failed to push the tag '#{current_version_name}' to remote\n"
    end
  end
end
