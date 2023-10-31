require "rails_helper"

RSpec.describe Organisation, type: :model do

  context "Test validation" do
    it "should be valid" do
      expect(FactoryBot.build(:organisation)).to be_valid
    end
  end

  context "Test asscociation" do
    it "should have many departments" do
      expect(Organisation.reflect_on_association(:departments).macro).to eq(:has_many)
    end

    it "should have many organisation_types" do
      expect(Organisation.reflect_on_association(:organisation_types).macro).to eq(:has_and_belongs_to_many)
    end

    it "should have many organisation images" do
      expect(Organisation.reflect_on_association(:organisation_images).macro).to eq(:has_many)
    end
  end

  context "Test scope" do
    it "search_query should be true" do
      expect(Organisation.search_query("mearto")).to match_array(Organisation.where("LOWER(organisations.name) LIKE ?", "mearto"))
    end

    it "sorted_by should be placement" do
      expect(Organisation.all.order("placement = 'Premium' DESC, placement = 'Basic' DESC, placement = 'Free' DESC")).to match_array(Organisation.all.order("placement = 'Premium' DESC, placement = 'Basic' DESC, placement = 'Free' DESC"))
    end

    it "sorted_by should be other" do
      expect(Organisation.sorted_by("desc")).to match_array(Organisation.order("organisations.name desc"))
    end

    it "with_distance should be true" do
      expect(Organisation.with_distance({city: 100, max_distance: 100})).to match_array(Organisation.near(100, 100))
    end
  end

  context "Test method" do
    let (:organisation) { FactoryBot.create(:organisation) }

    it "options_for_sorted_by success" do
      expect(Organisation.options_for_sorted_by.ids).to eq(Organisation.order("CASE
        WHEN placement = 'Premium' THEN '0'
        WHEN placement = 'Basic' THEN '1'
        ELSE '2'
        END ASC, name").ids)
    end

    it "full_address success" do
      expect(organisation.full_address).to eq("copenhagen, hej, Denmark" )
    end

    it "full_address success" do
      organisation.country_id = nil
      expect(organisation.full_address).to eq("copenhagen, hej" )
    end

    it "full_address success" do
      organisation.address2 = ""
      expect(organisation.full_address).to eq("copenhagen, , Denmark" )
    end

    it "country should success" do
      expect(organisation.country.data).to eq(Country.new("DK").data)
    end

    it "country should nil" do
      organisation.country_id = nil
      expect(organisation.country).to be_nil
    end

    it "country_name should success" do
      expect(organisation.country_name).to eq(Country.new("DK").data.alpha3)
    end

    it "country_name should nil" do
      organisation.country_id = nil
      expect(organisation.country).to be_nil
    end
  end
end
