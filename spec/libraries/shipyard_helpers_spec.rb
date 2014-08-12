# Encoding: UTF-8
#
# Cookbook Name:: shipyard
# Spec:: libraries/shipyard_helpers
#
# Copyright (C) 2014, Jonathan Hartman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative '../spec_helper'
require_relative '../../libraries/shipyard_helpers'

describe Shipyard::Helpers::Agent do
  let(:test_obj) { Class.new { include Shipyard::Helpers::Agent }.new }

  describe '#app_name' do
    it 'returns "shipyard-agent"' do
      expect(test_obj.app_name).to eq('shipyard-agent')
    end
  end

  describe '#default_docker_image' do
    it 'returns "shipyard/agent"' do
      expect(test_obj.send(:default_docker_image)).to eq('shipyard/agent')
    end
  end
end

describe Shipyard::Exceptions::MethodNotImplemented do
  describe '#initialize' do
    it 'generates a MethodNotImplemented exception' do
      expected = "Method 'test' needs to be implemented"
      expect(described_class.new(:test).message).to eq(expected)
    end
  end
end
