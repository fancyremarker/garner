require 'spec_helper'

describe "Sinatra integration" do

  let(:app) do
    class TestSinatraApp
      require "sinatra"

      helpers Garner::Mixins::Rack
      use Rack::ConditionalGet
      use Rack::ETag

      before do
        headers "Expires" => Time.at(0).utc.to_s
      end

      get "/" do
        garner do
          { meaning_of_life: 42 }.to_json
        end
      end
    end

    Sinatra::Application
  end

  it_should_behave_like "Rack::ConditionalGet server"

end
