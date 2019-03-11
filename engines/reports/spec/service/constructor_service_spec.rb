module Reports
  require 'main_spec_helper'
  describe ConstructorService do

    it '#class_info' do
      ConstructorService.class_info(['Core::Project']).inspect
    end

    it "usual select" do
      # puts User.all.to_a.map(&:email).inspect
      create(:city, title_ru: 'Воронеж')
      hash = {
                "class_name"=>"Core::City",
                "attributes"=>{"0"=>{"value"=>"title_ru", "label"=>"title_ru|string"}}
              }
      expect(ConstructorService.new(hash).to_a).to eq [{"title_ru"=>"Москва"}, {"title_ru"=>"Воронеж"}]
    end

    it "order by query" do
      create(:city, title_ru: 'Воронеж')
      hash = {"class_name"=>"Core::City", "attributes"=>{"0"=>{"value"=>"title_ru",
        "label"=>"title_ru|string", "order"=>"ASC"}}}
      expect(ConstructorService.new(hash).to_a).to eq [{"title_ru"=>"Воронеж"}, {"title_ru"=>"Москва"}]
    end

    it 'selects count' do
      create(:city, title_ru: 'Воронеж')
      hash = {"class_name"=>"Core::City", "attributes"=>{"0"=>{"value"=>"id",
          "label"=>"id|integer", "aggregate"=>"COUNT"}}}

      expect(ConstructorService.new(hash).to_a).to eq [{"count_id"=>2}]

    end

    it '#to_csv' do
      create(:city, title_ru: 'Воронеж')
      hash = {"class_name"=>"Core::City", "attributes"=>{"0"=>{"value"=>"id",
          "label"=>"id|integer", "aggregate"=>"COUNT"}}}

      puts ConstructorService.new(hash).to_csv.inspect

    end


    it "group by select" do
      country = create(:country, title_en: 'Germany')
      create(:city, title_en: 'Hamburg', country: country)
      create(:city, title_en: 'Frankfurt', country: country)
      hash = {"class_name"=>"Core::City", "attributes"=>{"0"=>{"value"=>"country_id",
         "label"=>"country_id|integer", "order"=>"GROUP"}, "1"=>{"value"=>
           "id", "label"=>"id|integer", "aggregate"=>"COUNT"}}}
      expect(ConstructorService.new(hash).to_a).to eq [{"country_id"=>country.id, "count_id"=>2},
        {"country_id"=>1, "count_id"=>1}]
    end

    it ".convert_left_to_inner" do
      hash =  {"accesses"=>{"join_type"=>"left", "project"=>{"join_type"=>"left",
              "card"=>{"join_type"=>"inner"}}, "fields"=>{"join_type"=>"left"}}}

      ConstructorService.convert_left_to_inner(hash)

      expect(hash).to eq("accesses"=>{"join_type"=>"inner", "project"=>{"join_type"=>"inner",
              "card"=>{"join_type"=>"inner"}}, "fields"=>{"join_type"=>"left"}})

    end
    it "queries with joins" do
      hash = {"class_name"=>"Core::City", "attributes"=>{"0"=>{
        "value"=>"title_ru", "label"=>"title_ru|string"}, "1"=>{
          "value"=>"organizations.projects.title",
          "label"=>"organizations.projects.title|string"}},
          "association"=>{"organizations"=>{"join_type"=>"inner",
            "projects"=>{"join_type"=>"left"}}}}
          ConstructorService.new(hash).to_a
            # expect(ConstructorService.new(hash).to_a).to eq [{"country_id"=>country.id, "count_id"=>2},
            #   {"country_id"=>1, "count_id"=>1}]

    end

    it "#where" do
      puts ConstructorService.where
    end


  end
end
