module Support
  class FieldValuesForm
    include ActiveModel::Model
    attr_reader :topics_fields, :ticket

    validate do
      topics_fields.each do |t_f|
        next unless t_f.required

        t_f_id = t_f.id.to_s
        # puts TopicsField.find(t_f_id).field.inspect.red
        value = send(t_f_id)
        if t_f.field.check_box?
          errors.add(t_f_id, :invalid) if !value || value.select(&:present?).count.zero?
        elsif value.blank?
          errors.add(t_f_id, :invalid)
        end
      end
    end

    def initialize(ticket, hash = nil)
      @ticket = ticket
      if hash
        hash.permit! if hash.is_a? ActionController::Parameters
        @topics_fields = ticket.topics_fields_to_fill
        new_fields = TopicsField.includes(:field).where(id: hash.keys)
                                .where
                                .not(field_id: topics_fields.map(&:field_id))
                                .to_a
        @topics_fields += new_fields
        define_methods_for_topics_fields(topics_fields)
        fill_values(hash)
        # puts new_fields.inspect.red
        # puts topics_fields.inspect.green
      elsif ticket.new_record?
        @topics_fields = ticket.topics_fields_to_fill
        define_methods_for_topics_fields(topics_fields)
      else
        @topics_fields = []
        ticket.field_values.group_by(&:topics_field)
              .each do |topics_field, field_values|
          @topics_fields << topics_field
          field_value = if topics_field.field.check_box?
            field_values.map(&:value).map(&:to_i)
          else
            field_values[0].value
          end
            define_singleton_method(topics_field.id.to_s) do
              field_value
            end
        end
        @topics_fields += ticket.empty_topic_fields
        define_methods_for_topics_fields(ticket.empty_topic_fields)
      end
    end

    def define_methods_for_topics_fields(current_topics_fields)
      current_topics_fields.each do |topics_field|
        define_singleton_method(topics_field.id.to_s) do
          ''
        end
      end
    end

    # def fill_value(topics_field_id:, **hash )
    #   ticket.field_values
    # end

    def fill_values(hash)
      ticket.field_values.each(&:mark_for_destruction)
      hash.each do |topics_field_id, values|
        if values.is_a? Array
          present_values = values.select(&:present?)
          present_values.each do |value|
            ticket.field_values.new(topics_field_id: topics_field_id, value: value)
          end
          if present_values.empty?
            ticket.field_values.new(topics_field_id: topics_field_id)
          end
          define_singleton_method(topics_field_id.to_s) do
            present_values.map(&:to_i)
          end
        else
          ticket.field_values.new(topics_field_id: topics_field_id, value: values)
          define_singleton_method(topics_field_id.to_s) do
            values
          end
        end
      end
    end
  end
end
