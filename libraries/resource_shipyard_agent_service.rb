# Encoding: UTF-8
#
# Cookbook Name:: shipyard
# Resource:: shipyard_agent_service
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

require 'chef/resource'
require 'chef/mixin/params_validate'
require_relative 'shipyard_helpers'
require_relative 'provider_shipyard_agent_service'
require_relative 'provider_shipyard_agent_service_container'
require_relative 'provider_shipyard_agent_service_standard'

class Chef
  class Resource
    # A Chef resource for the Shipyard agent service
    #
    # @author Jonathan Hartman <j@p4nt5.com>
    class ShipyardAgentService < Resource
      include Shipyard::Helpers::Agent

      attr_accessor :created

      provider_base Chef::Provider::ShipyardAgentService

      def initialize(name, run_context = nil)
        super
        @resource_name = :shipyard_agent_service
        @provider = Provider::ShipyardAgentService::Standard
        @action = [:create, :enable, :start]
        @allowed_actions = [:create, :delete, :enable, :disable, :start, :stop,
                            :restart]

        # State attributes set by the provider
        @created = false
      end

      #
      # The install type of the agent--standard (GitHub) or container
      #
      # @param [Symbol, String, NilClass] arg
      # @return [Symbol]
      #
      def install_type(arg = nil)
        res = set_or_return(:install_type,
                            arg.nil? ? arg : arg.to_sym,
                            kind_of: Symbol,
                            equal_to: [:standard, :container],
                            default: :standard)
        provider(arg.to_s.capitalize) if arg
        res
      end

      #
      # A path to the config file for the agent
      #
      # @param [String, NilClass]
      # @return [String]
      #
      def config_file(arg = nil)
        set_or_return(:config_file,
                      arg,
                      kind_of: String,
                      default: ::File.join('/etc/default', app_name),
                      callbacks: { 'Invalid config file provided' =>
                                   ->(a) { ::File.exist?(a) } })
      end

      #
      # The Docker image to be used for a container-based service
      #
      # @param [String, NilClass]
      # @return [String, NilClass]
      #
      def docker_image(arg = nil)
        set_or_return(
          :docker_image,
          arg,
          kind_of: [String, NilClass],
          default: install_type == :container ? default_docker_image : nil,
          callbacks: { 'A `docker_image` requires a container install' =>
                         ->(a) { a.nil? ? true : install_type == :container } }
        )
      end
    end
  end
end
