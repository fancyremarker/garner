require "spec_helper"
require "garner/mixins/rack"
require "grape"

describe "Grape integration" do
  class TestCachebuster < Grape::Middleware::Base
    def after
      @app_response[1]["Expires"] = Time.at(0).utc.to_s
      @app_response
    end
  end

  let(:app) do
    class TestGrapeApp < Grape::API
      helpers Garner::Mixins::Rack
      use Rack::ConditionalGet
      use Rack::ETag
      use TestCachebuster

      format :json

      get "/" do
        garner do
          { :meaning_of_life => 42 }.to_json
        end
      end

      get "/mongers" do
        garner.options({ :expires_in => 5.minutes }) do
          Monger.all
        end
      end
    end

    TestGrapeApp.new
  end

  it_behaves_like "Rack::ConditionalGet server"

  context "caching modified classes/objects" do
    include Rack::Test::Methods

    before(:each) do
      @object = Monger.create!({ :name => "M1" })
    end

    it "does not raise error when underlying classes are changed" do
      json = Monger.all.to_json
      browser = Rack::Test::Session.new(TestGrapeApp.new)
      browser.get "/mongers"
      browser.last_response.should be_successful
      browser.last_response.body.should == json

      TestGrapeApp.reset!
      class TestGrapeApp < Grape::API
        helpers Garner::Mixins::Rack

        format :json

        get "/mongers" do
          Monger.all
        end
      end

      browser = Rack::Test::Session.new(TestGrapeApp.new)
      browser.get "/mongers"
      browser.last_response.should be_successful
      browser.last_response.body.should == json
    end
  end
end
