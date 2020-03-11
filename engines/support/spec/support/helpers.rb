module Support
  module SpecHelpers
    def topics_field_by_kind_and_topic(topic, kind)
      topic.topics_fields.find_by_field_id(Field.find_by_kind(kind).id)
    end
  end
end
