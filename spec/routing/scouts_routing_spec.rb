require "rails_helper"

RSpec.describe ScoutsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/scouts").to route_to("scouts#index")
    end

    it "routes to #new" do
      expect(get: "/scouts/new").to route_to("scouts#new")
    end

    it "routes to #show" do
      expect(get: "/scouts/1").to route_to("scouts#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/scouts/1/edit").to route_to("scouts#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/scouts").to route_to("scouts#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/scouts/1").to route_to("scouts#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/scouts/1").to route_to("scouts#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/scouts/1").to route_to("scouts#destroy", id: "1")
    end
  end
end
