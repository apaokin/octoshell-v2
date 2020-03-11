module Support
  class FieldValuesForm
    include ActiveModel::Model
    attr_reader :ticket, :topics_fields, :old_fields
    validate do
      topics_fields.each do |t_f|
        next unless t_f.required

        t_f_id = t_f.field_id.to_s
        value = send(t_f_id)
        if t_f.field.check_box?
          errors.add(t_f_id, :blank) if !value || value.select(&:present?).count.zero?
        elsif value.blank?
          errors.add(t_f_id, :blank)
        end
      end
    end

    def initialize(ticket, hash = {})
      @ticket = ticket
      hash.permit! if hash.is_a? ActionController::Parameters
      @topics_fields = ticket.topics_fields_to_fill
      @old_fields = TopicsField.includes(:field).where(id: hash.keys)
                               .where
                               .not(field_id: topics_fields.map(&:field_id))
                               .to_a
      update_field_values(hash)
      topics_fields.each do |t_f|
        f_vs = ticket.field_values.select do |f_v|
          f_v.topics_field == t_f
        end
        unless hash.keys.include?(t_f.field_id.to_s)
          f_vs.each(&:mark_for_destruction)
        end
        define_singleton_method(t_f.field_id.to_s) do
          if f_vs.empty?
            handle_empty_f_v(t_f)
          elsif t_f.field.check_box?
            f_vs.map(&:value).map(&:to_i)
          elsif t_f.field.radio? || t_f.field.model_collection?
            f_vs.first.value.to_i
          else
            f_vs.first.value
          end
        end
      end
      old_fields.each do |t_f|
        define_singleton_method(t_f.field_id.to_s) do
          hash[t_f.field_id.to_s] || hash[t_f.field_id]
        end
      end
    end

    def handle_empty_f_v(t_f)
      if t_f.field.check_box?
        []
      else
        ''
      end
    end

    def update_select_value(topics_field, value)
      if ticket.field_values.none? do |f_v|
          f_v.topics_field == topics_field && f_v.value == value
        end
        ticket.field_values.new(topics_field: topics_field, value: value)
      end
    end

    def update_text_value(topics_field, value)
      if ticket.field_values.none? do |f_v|
        f_v.topics_field == topics_field
      end
        ticket.field_values.new(topics_field: topics_field, value: value)
      else
        ticket.field_values.detect do |f_v|
          f_v.topics_field == topics_field
        end.value = value
      end
    end

    def update_field_values(hash)
      hash.each do |field_id, values|
        topics_field = topics_fields.detect { |t_f| t_f.field_id == field_id.to_i }
        next unless topics_field

        if values.is_a? Array
          present_values = values.select(&:present?)
          ticket.field_values
                .select do |f_v|
                  f_v.topics_field == topics_field &&
                    !present_values.include?(f_v.value)
                end.each(&:mark_for_destruction)
          present_values.each do |value|
            update_select_value(topics_field, value)
          end
        else
          update_text_value(topics_field, values)
        end
      end
      ticket.field_values.select { |f_v| ['', nil].include?(f_v.value) }
            .each(&:mark_for_destruction)
    end
  end
end
