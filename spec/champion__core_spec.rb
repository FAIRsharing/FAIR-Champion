# spec/champion_core_spec.rb
require 'spec_helper'

RSpec.describe Champion::Core do
  let(:core) { described_class.new }
  let(:subject) { 'https://example.org/target/456' }
  let(:setid) { 'test_set' }
  let(:bmid) { 'https://example.org/benchmark/123' }

  describe '#get_test_endpoint_for_testid' do
    it 'fetches endpoint for a test ID', :vcr do
      stub_request(:post, 'https://tools.ostrails.eu/repositories/fdpindex-fdp')
        .to_return(
          status: 200,
          body: File.read('spec/support/fixtures/sample_sparql_response.json'),
          headers: { 'Content-Type' => 'application/sparql-results+json' }
        )
      endpoint = core.get_test_endpoint_for_testid(testid: 'https://tests.ostrails.eu/tests/fc_metadata_includes_license')
      expect(endpoint).to eq('https://tests.ostrails.eu/assess/test/fc_metadata_includes_license')
    end

    it 'returns nil when the FDP index has no endpoint for the test' do
      sparql_client = instance_double(SPARQL::Client, query: [])
      allow(SPARQL::Client).to receive(:new).and_return(sparql_client)

      endpoint = core.get_test_endpoint_for_testid(testid: 'https://tests.example/missing')

      expect(endpoint).to be_nil
    end
  end

  describe '#run_test' do
    it 'executes a test and returns JSON result', :vcr do
      stub_request(:post, 'https://tests.ostrails.eu/assess/test/fc_metadata_includes_license')
        .with(body: { 'resource_identifier' => subject }.to_json)
        .to_return(status: 200, body: { result: 'pass' }.to_json, headers: { 'Content-Type' => 'application/json' })
      result = core.run_test(
        testapi: 'https://tests.ostrails.eu/assess/test/fc_metadata_includes_license',
        guid: subject,
        testid: 'https://tests.ostrails.eu/tests/fc_metadata_includes_license'
      )
      expect(result).to eq('result' => 'pass')
    end

    it 'returns an indeterminate test result when the endpoint is missing' do
      testid = 'https://tests.example/missing'

      result = core.run_test(testapi: nil, guid: subject, testid: testid)

      expect(result).to include(
        '@type' => 'ftr:TestResult',
        'value' => 'indeterminate',
        'log' => "No dcat:endpointURL was found for test #{testid}",
        'outputFromTest' => { '@id' => testid }
      )
      expect(result['@id']).to start_with('urn:fairchampion:missing-endpoint:')
    end
  end
end
