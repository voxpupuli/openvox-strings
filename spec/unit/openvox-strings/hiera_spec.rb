# frozen_string_literal: true

require 'spec_helper'
require 'openvox-strings/hiera'
require 'tmpdir'
require 'fileutils'

describe OpenvoxStrings::Hiera do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe '#initialize' do
    context 'when hiera.yaml exists' do
      before do
        File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
          version: 5
          defaults:
            datadir: data
            data_hash: yaml_data
          hierarchy:
            - name: "Common defaults"
              path: "common.yaml"
        YAML
      end

      it 'loads hiera configuration' do
        hiera = described_class.new(temp_dir)
        expect(hiera.hiera_config).not_to be_nil
        expect(hiera.hiera_config['version']).to eq(5)
      end

      it 'is enabled' do
        hiera = described_class.new(temp_dir)
        expect(hiera).to be_hiera_enabled
      end
    end

    context 'when hiera.yaml does not exist' do
      it 'is not enabled' do
        hiera = described_class.new(temp_dir)
        expect(hiera).not_to be_hiera_enabled
      end
    end
  end

  describe '#find_first_static_layer_path' do
    context 'when a static layer exists' do
      before do
        File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
          version: 5
          defaults:
            datadir: data
            data_hash: yaml_data
          hierarchy:
            - name: "Common defaults"
              path: "common.yaml"
        YAML
      end

      it 'returns the full path to the static layer' do
        hiera = described_class.new(temp_dir)
        result = hiera.send(:find_first_static_layer_path)
        expect(result).to eq(File.join(temp_dir, 'data', 'common.yaml'))
      end
    end

    context 'when hierarchy contains interpolations before static layer' do
      before do
        File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
          version: 5
          defaults:
            datadir: data
            data_hash: yaml_data
          hierarchy:
            - name: "Per-node data"
              path: "nodes/%{facts.hostname}.yaml"
            - name: "Per-environment data"
              path: "env/%{facts.environment}.yaml"
            - name: "Common defaults"
              path: "common.yaml"
        YAML
      end

      it 'skips layers with interpolations and returns first static layer' do
        hiera = described_class.new(temp_dir)
        result = hiera.send(:find_first_static_layer_path)
        expect(result).to eq(File.join(temp_dir, 'data', 'common.yaml'))
      end
    end

    context 'when only interpolated layers exist' do
      before do
        File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
          version: 5
          defaults:
            datadir: data
            data_hash: yaml_data
          hierarchy:
            - name: "Per-node data"
              path: "nodes/%{facts.hostname}.yaml"
            - name: "Per-environment data"
              path: "env/%{environment}.yaml"
        YAML
      end

      it 'returns nil' do
        hiera = described_class.new(temp_dir)
        result = hiera.send(:find_first_static_layer_path)
        expect(result).to be_nil
      end
    end

    context 'when using custom datadir' do
      before do
        File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
          version: 5
          defaults:
            datadir: hieradata
            data_hash: yaml_data
          hierarchy:
            - name: "Common"
              path: "common.yaml"
        YAML
      end

      it 'uses the custom datadir' do
        hiera = described_class.new(temp_dir)
        result = hiera.send(:find_first_static_layer_path)
        expect(result).to eq(File.join(temp_dir, 'hieradata', 'common.yaml'))
      end
    end

    context 'when hierarchy uses paths instead of path' do
      before do
        File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
          version: 5
          defaults:
            datadir: data
            data_hash: yaml_data
          hierarchy:
            - name: "Multiple paths"
              paths:
                - "first.yaml"
                - "second.yaml"
        YAML
      end

      it 'uses the first path from paths array' do
        hiera = described_class.new(temp_dir)
        result = hiera.send(:find_first_static_layer_path)
        expect(result).to eq(File.join(temp_dir, 'data', 'first.yaml'))
      end
    end

    context 'when hierarchy is empty' do
      before do
        File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
          version: 5
          defaults:
            datadir: data
            data_hash: yaml_data
          hierarchy: []
        YAML
      end

      it 'returns nil' do
        hiera = described_class.new(temp_dir)
        result = hiera.send(:find_first_static_layer_path)
        expect(result).to be_nil
      end
    end
  end

  describe '#load_yaml_data' do
    context 'when file exists and is valid YAML' do
      before do
        FileUtils.mkdir_p(File.join(temp_dir, 'data'))
        File.write(File.join(temp_dir, 'data', 'test.yaml'), <<~YAML)
          key1: value1
          key2: 42
        YAML
      end

      it 'loads and parses the YAML file' do
        hiera = described_class.new(temp_dir)
        file_path = File.join(temp_dir, 'data', 'test.yaml')
        result = hiera.send(:load_yaml_data, file_path)
        expect(result).not_to be_nil
        expect(result['key1']).to eq('value1')
        expect(result['key2']).to eq(42)
      end
    end

    context 'when file does not exist' do
      it 'returns nil' do
        hiera = described_class.new(temp_dir)
        result = hiera.send(:load_yaml_data, File.join(temp_dir, 'nonexistent.yaml'))
        expect(result).to be_nil
      end
    end

    context 'when file contains invalid YAML' do
      before do
        FileUtils.mkdir_p(File.join(temp_dir, 'data'))
        File.write(File.join(temp_dir, 'data', 'invalid.yaml'), "invalid: yaml: content: [")
      end

      it 'returns nil and logs warning' do
        hiera = described_class.new(temp_dir)
        file_path = File.join(temp_dir, 'data', 'invalid.yaml')
        result = hiera.send(:load_yaml_data, file_path)
        expect(result).to be_nil
      end
    end
  end

  describe '#load_common_data' do
    context 'when common.yaml exists' do
      before do
        File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
          version: 5
          defaults:
            datadir: data
            data_hash: yaml_data
          hierarchy:
            - name: "Common defaults"
              path: "common.yaml"
        YAML

        FileUtils.mkdir_p(File.join(temp_dir, 'data'))
        File.write(File.join(temp_dir, 'data', 'common.yaml'), <<~YAML)
          testmodule::param1: 'value1'
          testmodule::param2: 42
          testmodule::param3: true
          testmodule::param4: ~
        YAML
      end

      it 'loads common data' do
        hiera = described_class.new(temp_dir)
        expect(hiera.common_data).not_to be_nil
        expect(hiera.common_data['testmodule::param1']).to eq('value1')
      end
    end
  end

  describe '#lookup_default' do
    before do
      File.write(File.join(temp_dir, 'hiera.yaml'), <<~YAML)
        version: 5
        defaults:
          datadir: data
          data_hash: yaml_data
        hierarchy:
          - name: "Common defaults"
            path: "common.yaml"
      YAML

      FileUtils.mkdir_p(File.join(temp_dir, 'data'))
      File.write(File.join(temp_dir, 'data', 'common.yaml'), <<~YAML)
        circus::tent_size: 'large'
        circus::location: '/opt/circus-ground'
        circus::season: '2025'
        circus::ringmaster: 'Giovanni'
        circus::has_animals: false
        circus::performers: {}
        circus::insurance_policy: ~
      YAML
    end

    let(:hiera) { described_class.new(temp_dir) }

    it 'returns string values with quotes' do
      result = hiera.lookup_default('circus', 'tent_size')
      expect(result).to eq("'large'")
    end

    it 'returns string paths with quotes' do
      result = hiera.lookup_default('circus', 'location')
      expect(result).to eq("'/opt/circus-ground'")
    end

    it 'returns string version numbers with quotes' do
      result = hiera.lookup_default('circus', 'season')
      expect(result).to eq("'2025'")
    end

    it 'returns string names with quotes' do
      result = hiera.lookup_default('circus', 'ringmaster')
      expect(result).to eq("'Giovanni'")
    end

    it 'returns boolean false as false' do
      result = hiera.lookup_default('circus', 'has_animals')
      expect(result).to eq('false')
    end

    it 'returns empty hash as {}' do
      result = hiera.lookup_default('circus', 'performers')
      expect(result).to eq('{}')
    end

    it 'returns nil/undef as undef' do
      result = hiera.lookup_default('circus', 'insurance_policy')
      expect(result).to eq('undef')
    end

    it 'returns nil for non-existent keys' do
      result = hiera.lookup_default('circus', 'nonexistent')
      expect(result).to be_nil
    end

    it 'returns nil for wrong class name' do
      result = hiera.lookup_default('wrong_module', 'tent_size')
      expect(result).to be_nil
    end
  end

  describe '#value_to_puppet_string' do
    let(:hiera) { described_class.new(temp_dir) }

    it 'converts strings with quotes' do
      expect(hiera.send(:value_to_puppet_string, 'hello')).to eq("'hello'")
    end

    it 'converts integers without quotes' do
      expect(hiera.send(:value_to_puppet_string, 42)).to eq('42')
    end

    it 'converts floats without quotes' do
      expect(hiera.send(:value_to_puppet_string, 3.14)).to eq('3.14')
    end

    it 'converts true to lowercase true' do
      expect(hiera.send(:value_to_puppet_string, true)).to eq('true')
    end

    it 'converts false to lowercase false' do
      expect(hiera.send(:value_to_puppet_string, false)).to eq('false')
    end

    it 'converts nil to undef' do
      expect(hiera.send(:value_to_puppet_string, nil)).to eq('undef')
    end

    it 'converts empty arrays' do
      expect(hiera.send(:value_to_puppet_string, [])).to eq('[]')
    end

    it 'converts arrays with values' do
      expect(hiera.send(:value_to_puppet_string, %w[a b])).to eq("['a', 'b']")
    end

    it 'converts empty hashes' do
      expect(hiera.send(:value_to_puppet_string, {})).to eq('{}')
    end

    it 'converts hashes with values' do
      result = hiera.send(:value_to_puppet_string, { 'key' => 'value' })
      expect(result).to eq("{ 'key' => 'value' }")
    end

    it 'converts nested structures' do
      nested = { 'array' => [1, 2], 'nested_hash' => { 'key' => 'value' } }
      result = hiera.send(:value_to_puppet_string, nested)
      expect(result).to include("'array' => [1, 2]")
      expect(result).to include("'nested_hash' => { 'key' => 'value' }")
    end

    it 'formats arrays without spaces to match code defaults' do
      # Arrays must use ['a', 'b'] not [ 'a', 'b' ] to match puppet-strings code format
      result = hiera.send(:value_to_puppet_string, %w[alpha beta gamma])
      expect(result).to eq("['alpha', 'beta', 'gamma']")
      expect(result).not_to include('[ ')
      expect(result).not_to include(' ]')
    end

    it 'formats integer arrays without spaces to match code defaults' do
      result = hiera.send(:value_to_puppet_string, [1, 2, 3, 5, 8])
      expect(result).to eq('[1, 2, 3, 5, 8]')
      expect(result).not_to include('[ ')
      expect(result).not_to include(' ]')
    end

    it 'formats nested arrays in hashes without spaces' do
      nested = { 'tags' => %w[prod eu] }
      result = hiera.send(:value_to_puppet_string, nested)
      expect(result).to eq("{ 'tags' => ['prod', 'eu'] }")
      expect(result).not_to include('[ ')
      expect(result).not_to include(' ]')
    end
  end
end
