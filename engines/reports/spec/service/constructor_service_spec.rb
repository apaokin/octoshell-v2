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
      expect(ConstructorService.new(hash).to_a).to eq [{"title_ru"=>"Воронеж"}, {"title_ru"=>"Москва"}]
    end

    it "order by query" do
      create(:city, title_ru: 'Воронеж')
      hash = {"class_name"=>"Core::City", "attributes"=>{"0"=>{"value"=>"title_ru",
        "label"=>"title_ru|string", "order"=>"ASC"}}}
      puts ConstructorService.new(hash).to_sql
      expect(ConstructorService.new(hash).to_a).to eq [{"title_ru"=>"Воронеж"}, {"title_ru"=>"Москва"}]
    end

    it 'selects count' do
      create(:city, title_ru: 'Воронеж')
      hash = {"class_name"=>"Core::City", "attributes"=>{"0"=>{"value"=>"id",
          "label"=>"id|integer", "aggregate"=>"COUNT"}}}

      expect(ConstructorService.new(hash).to_a).to eq [{"count_id"=>'2'}]

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
      expect(ConstructorService.new(hash).to_a).to match_array [{"country_id"=>country.id.to_s, "count_id"=>2.to_s},
        {"country_id"=>'1', "count_id"=>'1'}]
    end

    it ".convert_left_to_inner" do
      hash =  {"accesses"=>{"join_type"=>"left", "project"=>{"join_type"=>"left",
              "card"=>{"join_type"=>"inner"}}, "fields"=>{"join_type"=>"left"}}}

      ConstructorService.convert_left_to_inner(hash)

      expect(hash).to eq("accesses"=>{"join_type"=>"inner", "project"=>{"join_type"=>"inner",
              "card"=>{"join_type"=>"inner"}}, "fields"=>{"join_type"=>"left"}})

    end
    it "queries with joins" do
      # country = create(:country, title_en: 'Germany')
      # create(:city, title_en: 'Hamburg', country: country)
      # create(:city, title_en: 'Frankfurt', country: country)

      hash = {"class_name"=>"Core::City", "attributes"=>{"0"=>{
        "value"=>"title_ru", "label"=>"title_ru|string"}, "1"=>{
          "value"=>"organizations.projects.title",
          "label"=>"organizations.projects.title|string"}},
          "association"=>{"organizations"=>{"join_type"=>"inner",
            "projects"=>{"join_type"=>"left"}}}}

      puts ConstructorService.new(hash).to_a
            # expect(ConstructorService.new(hash).to_a).to eq [{"country_id"=>country.id, "count_id"=>2},
            #   {"country_id"=>1, "count_id"=>1}]

    end

    it "group by with assocations" do
      org1 = create(:organization, name: 'org1')
      org2 = create(:organization, name: 'org2')
      create(:organization_department, organization: org1)
      create(:organization_department, organization: org1)
      create(:organization_department, organization: org2)
      create(:organization_department, organization: org2)
      create(:organization_department, organization: org2)

      hash = {"class_name"=>"Core::Organization", "attributes"=>{"0"=>{"value"=>"name", "label"=>"name|string", "order"=>["GROUP"]},
              "1"=>{"value"=>"departments.id", "label"=>"departments.id|integer", "aggregate"=>"COUNT"}},
              "association"=>{"list"=>"departments", "departments"=>{"join_type"=>"inner"}}}
      # puts ConstructorService.new(hash).to_sql
      constructor = ConstructorService.new(hash)
      ActiveRecord::Base.logger = Logger.new(STDOUT) if defined?(ActiveRecord::Base)
      puts constructor.count.inspect.blue
      puts ConstructorService.new(hash).to_a
    end



    it "performs custom inner join with base table" do

      org1 = create(:organization, name: 'org1')
      org2 = create(:organization, name: 'org2')

      params = {"class_name"=>"Core::Organization", "attributes"=>{"0"=>{"value"=>"name",
                "label"=>"name|string"}, "1"=>{"value"=>"c_core_organization_kinds.name_ru",
                "label"=>"c_core_organization_kinds.name_ru|string"}}, "association"=>
                {"custom-join-1557138479832"=>{"join_table"=>"Core::OrganizationKind",
                  "alias"=>"c_core_organization_kinds", "join_type"=>"inner",
                  "on"=>"kind_id= c_core_organization_kinds.id"}}}

      puts Core::OrganizationKind.all.to_a.inspect
      puts ConstructorService.new(params).to_sql.inspect.blue
      puts ConstructorService.new(params).to_a.inspect
      # ConstructorService.new(params).to_a.inspect


    end

    it "rewrites having for db" do
      org1 = create(:organization, name: 'org1')
      org2 = create(:organization, name: 'org2')
      kind_name_ru = org1.kind.name_ru
      params = {"class_name"=>"Core::Organization", "attributes"=>{"0"=>{"value"=>"kind.name_ru",
             "label"=>"kind.name_ru|string"}, "1"=>{"value"=>"name", "label"=>"name|string"}},
             "association"=>{"list"=>"kind", "kind"=>{"join_type"=>"inner"}},
             "where"=>"kind.name_ru = '#{kind_name_ru}'", "per"=>"20"}
      puts ConstructorService.new(params).to_a.inspect
    end

    it "rewrites on for db" do
      # org1 = create(:organization, name: 'org1')
      # org2 = create(:organization, name: 'org2')
      # kind_name_ru = org1.kind.name_ru
      params = {"class_name"=>"Core::Cluster", "attributes"=>{"0"=>{"value"=>"admin_login",
        "label"=>"admin_login|string"}}, "association"=>
        {"custom-join-1557265646481"=>{"join_table"=>"Core::Cluster",
          "alias"=>"c_core_clusters", "join_type"=>"inner",
          "on"=>"id=c_core_clusters.id"}}, "per"=>"20"}
      puts ConstructorService.new(params).to_a.inspect
    end



  end
end
