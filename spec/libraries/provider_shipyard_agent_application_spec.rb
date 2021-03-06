# Encoding: UTF-8
#
# Cookbook Name:: shipyard
# Spec:: libraries/provider_shipyard_agent_application
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
require_relative '../../libraries/provider_shipyard_agent_application'

describe Chef::Provider::ShipyardAgentApplication do
  let(:new_resource) do
    double(name: 'my_agent',
           install_type: :standard)
  end
  let(:provider) { described_class.new(new_resource, nil) }

  describe '#whyrun_supported' do
    it 'advertises WhyRun support' do
      expect(provider.whyrun_supported?).to eq(true)
    end
  end

  describe '#load_current_resource' do
    before(:each) do
      allow_any_instance_of(described_class).to receive(:installed?)
        .and_return(true)
      allow_any_instance_of(described_class).to receive(:version)
        .and_return('1.2.3')
    end

    it 'returns an instance of the application resource' do
      expected = Chef::Resource::ShipyardAgentApplication
      expect(provider.load_current_resource).to be_an_instance_of(expected)
    end
  end

  [
    :action_create,
    :action_delete,
    :action_install,
    :action_uninstall,
    :installed?,
    :version
  ].each do |m|
    describe "##{m}" do
      it 'raises an exception' do
        expected = Shipyard::Exceptions::MethodNotImplemented
        expect { provider.send(m) }.to raise_error(expected)
      end
    end
  end
end
