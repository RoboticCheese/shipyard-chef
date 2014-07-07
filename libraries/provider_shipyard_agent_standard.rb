# Encoding: UTF-8
#
# Cookbook Name:: shipyard
# Provider:: shipyard_agent
#
# Copyright 2014, Jonathan Hartman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/provider'
require 'chef/resource/chef_gem'
require 'chef/resource/directory'
require 'chef/resource/remote_file'
require 'chef/resource/template'
require 'fileutils'
require 'mixlib/shellout'
require 'uri'
require_relative 'resource_shipyard_agent'

class Chef
  class Provider
    class ShipyardAgent < Provider
      # A Chef provider for a standard (GitHub) Shipyard agent install
      #
      # @author Jonathan Hartman <j@p4nt5.com>
      class Standard < ShipyardAgent
        attr_accessor :current_resource

        #
        # Check whether the Shipyard agent is installed
        #
        # @return [TrueClass, FalseClass]
        #
        def installed?
          ::File.exist?(::File.join(deploy_dir, asset_file))
        end

        #
        # Get the version of the agent installed
        #
        # @return [String]
        #
        def installed_version
          shout = Mixlib::ShellOut.new("#{deploy_dir}/#{asset_file} --version")
          shout.run_command.stdout.strip
        end

        #
        # Install the Shipyard agent via GitHub artifact repo
        #
        def action_install
          chef_gem.run_action(:install)
          if current_resource.installed? && !needs_updowngrade?
            Chef::Log.info("Skipping #{current_resource}, #{release} " \
                           '(already installed)')
          else
            Chef::Log.info("Installing #{current_resource}, #{release}")
            # TODO: Create a bin/ subdir and put the script there
            [directory, remote_file, init_script, conf_file].each do |r|
              r.run_action(:create)
            end
          end
        end

        #
        # Delete the Shipyard agent's deployed files
        #
        def action_uninstall
          if current_resource.installed?
            Chef::Log.info("Uninstalling #{current_resource}")
            [conf_file, init_script, remote_file].each do |f|
              f.run_action(:delete)
            end
            directory.run_action(:delete) if ::Dir.new(deploy_dir).count == 2
          else
            Chef::Log.info("Skipping #{current_resource} (not installed)")
          end
        end

        private

        #
        # The agent config file
        #
        # @return [Chef::Resource::Template]
        #
        # TODO: Make the conf file its own Chef resource/provider
        def conf_file
          @conf_file ||= Chef::Resource::Template.new(
            ::File.join('/etc/default', "#{asset_file}.conf"), run_context
          )
          @conf_file.cookbook(new_resource.cookbook_name.to_s)
          @conf_file.source('shipyard-agent.default.erb')
          @conf_file.variables(host_url: new_resource.host,
                               key: new_resource.key)
          @conf_file
        end

        #
        # The init script file (Upstart only)
        #
        # @return [Chef::Resource::Template]
        #
        # TODO: Make the init file its own Chef resource/provider
        def init_script
          @init_script ||= Chef::Resource::Template.new(
            ::File.join('/etc/init', asset_file), run_context
          )
          @init_script.cookbook(new_resource.cookbook_name.to_s)
          @init_script.source('upstart/shipyard-agent.conf.init.erb')
          @init_script
        end

        #
        # The RemoteFile resource for the deployed artifact
        #
        # @return [Chef::Resource::RemoteFile]
        #
        def remote_file
          @remote_file ||= Chef::Resource::RemoteFile.new(
            ::File.join(deploy_dir, asset_file), run_context
          )
          @remote_file.mode('0755')
          @remote_file.source(asset_url.to_s)
          @remote_file
        end

        #
        # The Directory resource for the deployed artifact
        #
        # @return [Chef::Resource::Directory]
        #
        def directory
          @directory ||= Chef::Resource::Directory.new(deploy_dir, run_context)
          @directory.recursive(true)
          @directory
        end

        #
        # The ChefGem resource for octokit
        #
        # @return [Chef::Resource::ChefGem]
        #
        def chef_gem
          @chef_gem ||= Chef::Resource::ChefGem.new('octokit', run_context)
        end

        #
        # Construct a full URL to the GitHub release
        #
        # @return [URI]
        def asset_url
          URI("https://github.com/#{repo}/releases/download/#{release}/" <<
              asset_file)
        end

        #
        # The filename for the GitHub asset
        #
        # @return [String]
        #
        def asset_file
          # TODO: Don't hard code this here
          'shipyard-agent'
        end

        #
        # Translate the 'version' of the resource to a GitHub release string
        #
        # @return [String]
        #
        def release
          case new_resource.version
          when 'latest'
            require 'octokit'
            Octokit.releases(repo).first[:tag_name]
          else
            "v#{new_resource.version}"
          end
        end

        #
        # The GitHub repo for the Shipyard agent
        #
        # @return [String]
        #
        def repo
          "shipyard/#{asset_file}"
        end

        #
        # The directory to which deploys are done
        #
        # @return [String]
        #
        def deploy_dir
          '/usr/bin'
        end
      end
    end
  end
end
